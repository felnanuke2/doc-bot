import Foundation

protocol ChunkEmbeddingRepository {
    /// Embeds a chunk of text into a vector representation.
    /// - Parameter chunk: The chunk to embed.
    /// - Returns: An array of doubles representing the embedded vector.
    /// This method is used to convert text into a format suitable for vector storage and search.
    func embed(chunk: EmbeddableChunk, with model: LocalModel) async -> [Float]
    
    /// Embeds multiple chunks of text into vector representations in a single batch operation.
    /// This is significantly more efficient than calling embed(chunk:) multiple times.
    /// - Parameters:
    ///   - chunks: The chunks to embed.
    ///   - model: The local model to use for embedding.
    /// - Returns: An array of embedding vectors, one for each input chunk.
    func embed(chunks: [EmbeddableChunk], with model: LocalModel) async -> [[Float]]
}

/// Protocol for types that can store and retrieve embeddings.
/// This protocol defines the methods for managing embeddings in a vector store.
protocol VectorChunkRepository {
    /// Retrieves the closest chunks to a given embedding for a specific document.
    /// - Parameters:
    ///   - documentID: The ID of the document to search within.
    ///   - embedding: The embedding vector to compare against.
    ///   - topK: The number of closest chunks to return.
    /// - Returns: An array of `StoredChunk` that are closest to the embedding
    func closestChunks(documentID: UUID, to embedding: [[Float]], topK: Int) async -> [StoredChunk]

    /// Finds the K closest chunks to a given query text using semantic similarity.
    /// - Parameters:
    ///   - documentID: The ID of the document to search within.
    ///   - queryText: The query string to compare against chunk content.
    ///   - topK: The number of closest chunks to return.
    /// - Returns: An array of `StoredChunk` that are closest to the query text
    func closestChunks(documentID: UUID, to queryText: String, topK: Int) async -> [StoredChunk]
    /// Adds a chunk to the vector store.
    /// - Parameter chunk: The chunk to add.
    /// - Returns: Void
    func addChunk(_ chunk: EmbeddableChunk, embedding: [Float]) async
    

    /// Adds multiple chunks to the vector store in a single operation.
    /// This is more efficient than calling addChunk(_:embedding:) multiple times.
    /// - Parameter chunks: An array of tuples where each tuple contains an `EmbeddableChunk` and its corresponding embedding vector.
    /// - Returns: Void
    func addChunk(_ chunks: [(EmbeddableChunk, [Float])]) async
    

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
