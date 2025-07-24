//
//  NaturalLanguageChunkGenerator.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//


import Foundation
import NaturalLanguage



/// A chunk generator that uses the Natural Language framework to create consistently sized chunks of text.
///
/// This implementation groups sentences together to form chunks that are close to a target word count.
/// This is more effective for embedding than splitting by paragraphs, which can result in chunks
/// that are too small or vary widely in size.
class NaturalLanguageChunkGenerator: ChunkGeneratorRepository {
    
    /// The target word count for each chunk.
    ///
    /// The 512 token limit for many embedding models roughly corresponds to 350-400 English words.
    /// We use 384 as a conservative target to ensure the resulting chunks are under the limit.
    private let chunkTargetWordCount = 200
    
    /// Generates chunks by grouping sentences to reach a target word count.
    func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk] {
        var chunks: [EmbeddableChunk] = []
        
        // Use NLTokenizer to split the text by sentence for more granular control.
        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.string = text
        
        // Extract all sentences from the text.
        let sentences = sentenceTokenizer.tokens(for: text.startIndex..<text.endIndex).map {
            text[$0].trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        
        
        guard !sentences.isEmpty else {
            return []
        }
        
        var currentChunkSentences: [String] = []
        var currentChunkWordCount = 0
        
        for sentence in sentences {
            // Estimate word count for the new sentence. A simple split by space is a good approximation.
            let sentenceWordCount = sentence.split(separator: " ").count
            
            // If the current chunk is not empty and adding the new sentence would push it over the target size,
            // then we should finalize the current chunk and start a new one.
            if currentChunkWordCount > 0 && (currentChunkWordCount + sentenceWordCount > chunkTargetWordCount) {
                let chunkContent = currentChunkSentences.joined(separator: " ")
                chunks.append(EmbeddableChunk(content: chunkContent, documentID: documentID))
                
                // Start a new chunk with the current sentence.
                currentChunkSentences = [sentence]
                currentChunkWordCount = sentenceWordCount
            } else {
                // Otherwise, add the new sentence to the current chunk.
                currentChunkSentences.append(sentence)
                currentChunkWordCount += sentenceWordCount
            }
        }
        
        // After the loop, there might be a remaining chunk that hasn't been added yet.
        // Add the last chunk if it contains any sentences.
        if !currentChunkSentences.isEmpty {
            let finalChunkContent = currentChunkSentences.joined(separator: " ")
            chunks.append(EmbeddableChunk(content: finalChunkContent, documentID: documentID))
        }
        
        return chunks
    }
}
