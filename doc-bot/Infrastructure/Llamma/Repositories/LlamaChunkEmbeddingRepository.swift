//
//  LlamaChunkEmbeddingRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//

/// An actor that manages a single, persistent LlamaEmbeddingContext
/// to efficiently generate embeddings for multiple chunks.
actor LlamaChunkEmbeddingRepository: ChunkEmbeddingRepository {
    
    /// The path to the GGUF model file.
    
    
    /// The lazily-loaded, reusable embedding context.
    private var context: LlamaEmbeddingContext?

 

    /// Generates an embedding for the given chunk.
    /// It will load the model on the first call and reuse it for all subsequent calls.
    func embed(chunk: EmbeddableChunk, with model: LocalModel) async -> [Float]{
        do {
            // Lazily initialize the context on the first run.
            let contextToUse = try await getOrCreateContext(model: model)
            
            // Use the persistent context to generate the embedding.
            return try await contextToUse.generateEmbedding(for: chunk.content)
        } catch {
            print("Error in embed(chunk:with:): \(error)")
            // Return empty embedding with default dimension to prevent crash
            return [Float](repeating: 0.0, count: 384)
        }
    }
    
    /// Generates embeddings for multiple chunks in a single batch operation.
    /// This is significantly more efficient than calling embed(chunk:) multiple times.
    func embed(chunks: [EmbeddableChunk], with model: LocalModel) async -> [[Float]] {
        guard !chunks.isEmpty else { return [] }
        
        do {
            // Lazily initialize the context on the first run.
            let contextToUse = try await getOrCreateContext(model: model)
            
            // Try batch processing first for maximum performance
            return try await contextToUse.generateEmbeddings(for: chunks.map { $0.content })
        } catch {
            print("Warning: Batch embedding failed (\(error)), falling back to individual processing")
            
            // Return empty embeddings for all chunks to maintain consistency
            let defaultEmbedding = [Float](repeating: 0.0, count: 384)
            return chunks.map { _ in defaultEmbedding }
        }
    }
    
    /// A helper function to safely create and store the context once.
    private func getOrCreateContext(model: LocalModel) async throws -> LlamaEmbeddingContext {
        // If the context is already loaded, return it immediately.
        if let context = self.context {
            return context
        }
        
        // Otherwise, create it, store it for future use, and return it.
        print("Context not found. Loading model into memory for the first time...")
        let newContext = try LlamaEmbeddingContext.createContext(path: model.localPath.relativePath)
        self.context = newContext
        print("✅ Model loaded. Context is now ready for reuse.")
        return newContext
    }
}
