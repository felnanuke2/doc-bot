import Foundation

protocol ChunkEmbeddingRepository {
    /// Embeds a chunk of text into a vector representation.
    /// - Parameter chunk: The chunk to embed.
    /// - Returns: An array of doubles representing the embedded vector.
    /// This method is used to convert text into a format suitable for vector storage and search.
    func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk
    
    /// Embeds multiple chunks of text into vector representations in a single batch operation.
    /// This is significantly more efficient than calling embed(chunk:) multiple times.
    /// - Parameters:
    ///   - chunks: The chunks to embed.
    ///   - model: The local model to use for embedding.
    /// - Returns: An array of embedding vectors, one for each input chunk.
    func embed(chunks: [EmbeddableChunk]) async -> [EmbeddedChunk]
    
    
    func searchRelevantChunk(for query: String, chunks: [EmbeddedChunk], limit: Int) async -> [EmbeddedChunk]
}

/// Protocol for types that can store and retrieve embeddings.
/// This protocol defines the methods for managing embeddings in a vector store.
protocol VectorChunkRepository {
    /// each time this is called will override last if documentId is the same or will create if not existent already
    func store(embedded: [EmbeddedChunk], for documentID: UUID) async
    
    /// return the chunkd if already stored or null if not existent
    func restoreEmbeddings(for documentID: UUID) async -> [EmbeddedChunk]?
}

/// Protocol for types that can generate chunks from text.
protocol ChunkGeneratorRepository {
    /// Generates chunks from the provided text.
    /// - Parameter text: The text to generate chunks from.
    /// - Returns: An array of `EmbeddableChunk` generated from the text.
    func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk]
}

/// Protocol for types that can extract text content from various document files.
protocol DocumentContentExtractor {
    /// Extracts the textual content from a file at the given URL.
    /// - Parameter fileURL: The URL of the file to extract content from.
    /// - Returns: The extracted text content as a String, or nil if extraction fails.
    func extractContent(from fileURL: URL) async -> String?
}
