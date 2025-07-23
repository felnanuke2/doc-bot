//
//  NaturalLanguageChunkEmbeddingRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/07/25.
//

import NaturalLanguage
import Foundation

/// An actor that manages embeddings using Apple's NaturalLanguage framework
/// This provides built-in word and sentence embeddings without requiring external models.
actor NaturalLanguageChunkEmbeddingRepository: ChunkEmbeddingRepository {
    
    /// The sentence embedding model for generating embeddings
    private var sentenceEmbedding: NLEmbedding?
    
    /// The word embedding model for fallback scenarios
    private var wordEmbedding: NLEmbedding?
    
    /// Default embedding dimension for consistency
    private let defaultEmbeddingDimension: Int = 512 // Apple's sentence embeddings are typically 512-dimensional
    
    init() {
        // Initialize embeddings for English language
        self.sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        self.wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }
    
    /// Generates an embedding for the given chunk using Apple's NaturalLanguage framework.
    /// Uses sentence embeddings for better semantic understanding of text chunks.
    func embed(chunk: EmbeddableChunk, with model: LocalModel) async -> [Float] {
        do {
            return try await generateEmbedding(for: chunk.content)
        } catch {
            print("Error in embed(chunk:with:): \(error)")
            // Return empty embedding with default dimension to prevent crash
            return [Float](repeating: 0.0, count: defaultEmbeddingDimension)
        }
    }
    
    /// Generates embeddings for multiple chunks in a single batch operation.
    /// This processes each chunk individually using Apple's NaturalLanguage framework.
    func embed(chunks: [EmbeddableChunk], with model: LocalModel) async -> [[Float]] {
        guard !chunks.isEmpty else { return [] }
        
        do {
            var embeddings: [[Float]] = []
            
            for chunk in chunks {
                let embedding = try await generateEmbedding(for: chunk.content)
                embeddings.append(embedding)
            }
            
            return embeddings
        } catch {
            print("Warning: Batch embedding failed (\(error)), returning default embeddings")
            
            // Return empty embeddings for all chunks to maintain consistency
            let defaultEmbedding = [Float](repeating: 0.0, count: defaultEmbeddingDimension)
            return chunks.map { _ in defaultEmbedding }
        }
    }
    
    /// Private helper to generate embeddings using Apple's NaturalLanguage framework
    private func generateEmbedding(for text: String) async throws -> [Float] {
        // First try sentence embedding for better semantic understanding
        if let sentenceEmbedding = self.sentenceEmbedding,
           let vector = sentenceEmbedding.vector(for: text) {
            print("✅ Generated sentence embedding for text (dimension: \(vector.count))")
            return vector.map { Float($0) } // Convert [Double] to [Float]
        }
        
        // Fallback to word embedding if sentence embedding fails
        if let wordEmbedding = self.wordEmbedding {
            return try await generateWordBasedEmbedding(for: text, using: wordEmbedding)
        }
        
        // If both fail, throw an error
        throw EmbeddingError.noEmbeddingAvailable
    }
    
    /// Generates an embedding by averaging word embeddings when sentence embedding is not available
    private func generateWordBasedEmbedding(for text: String, using wordEmbedding: NLEmbedding) async throws -> [Float] {
        // Tokenize the text into words
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var wordVectors: [[Float]] = []
        var wordCount = 0
        
        // Get embeddings for each word
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let word = String(text[tokenRange]).lowercased()
            
            if let vector = wordEmbedding.vector(for: word) {
                wordVectors.append(vector.map { Float($0) }) // Convert [Double] to [Float]
                wordCount += 1
            }
            
            return true
        }
        
        // If no word embeddings were found, return default
        guard !wordVectors.isEmpty else {
            throw EmbeddingError.noWordsFound
        }
        
        // Average the word vectors to create a document embedding
        let embeddingDimension = wordVectors[0].count
        var averagedEmbedding = [Float](repeating: 0.0, count: embeddingDimension)
        
        for vector in wordVectors {
            for i in 0..<embeddingDimension {
                averagedEmbedding[i] += vector[i]
            }
        }
        
        // Normalize by word count
        for i in 0..<embeddingDimension {
            averagedEmbedding[i] /= Float(wordCount)
        }
        
        print("✅ Generated word-based embedding for text (dimension: \(embeddingDimension), words: \(wordCount))")
        return averagedEmbedding
    }
    
    /// Calculates semantic similarity between two text chunks
    /// Returns a value between 0.0 (identical) and 2.0 (completely different)
    func calculateSimilarity(between chunk1: EmbeddableChunk, and chunk2: EmbeddableChunk) async -> Float {
        guard let sentenceEmbedding = self.sentenceEmbedding else {
            print("Warning: Sentence embedding not available for similarity calculation")
            return 2.0 // Maximum distance when unavailable
        }
        
        let distance = sentenceEmbedding.distance(between: chunk1.content, and: chunk2.content)
        return Float(distance)
    }
    
    /// Finds chunks most similar to the given query chunk
    func findSimilarChunks(to query: EmbeddableChunk, in chunks: [EmbeddableChunk], maximumCount: Int = 5) async -> [(chunk: EmbeddableChunk, similarity: Float)] {
        guard let sentenceEmbedding = self.sentenceEmbedding else {
            print("Warning: Sentence embedding not available for similarity search")
            return []
        }
        
        var similarities: [(chunk: EmbeddableChunk, similarity: Float)] = []
        
        for chunk in chunks {
            let distance = sentenceEmbedding.distance(between: query.content, and: chunk.content)
            similarities.append((chunk: chunk, similarity: Float(distance)))
        }
        
        // Sort by similarity (lower distance = more similar)
        similarities.sort { $0.similarity < $1.similarity }
        
        // Return top results
        return Array(similarities.prefix(maximumCount))
    }
}

/// Custom errors for the NaturalLanguage embedding repository
enum EmbeddingError: Error {
    case noEmbeddingAvailable
    case noWordsFound
    case invalidText
    
    var localizedDescription: String {
        switch self {
        case .noEmbeddingAvailable:
            return "No embedding model available for the specified language"
        case .noWordsFound:
            return "No valid words found in the input text"
        case .invalidText:
            return "The input text is invalid or empty"
        }
    }
}
