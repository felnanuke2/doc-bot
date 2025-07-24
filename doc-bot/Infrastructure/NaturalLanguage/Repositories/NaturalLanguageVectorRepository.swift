import Foundation
import NaturalLanguage

/// Stores chunks and uses a true vector similarity search.
class NaturalLanguageVectorRepository: VectorChunkRepository {
    func closestChunks(documentID: UUID, to queryText: String, topK: Int) async -> [StoredChunk] {
        return []
    }
    
    private var indices: [UUID: [StoredChunk]] = [:]
    private let appDirectoryURL: URL
    

    init() {
        guard
            let applicationSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            fatalError("Could not find Application Support directory.")
        }
        let appDirectoryURL = applicationSupportURL.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "doc-bot")
        if !FileManager.default.fileExists(atPath: appDirectoryURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Could not create app directory in Application Support: \(error)")
            }
        }
        self.appDirectoryURL = appDirectoryURL
    }

    /// Adds multiple chunks and their embeddings to storage in a single operation.
    func addChunk(_ chunks: [(EmbeddableChunk, [Float])]) async {
        let grouped = Dictionary(grouping: chunks, by: { $0.0.documentID })
        for (documentID, chunkTuples) in grouped {
            await self.loadIndices(for: documentID)
            var documentChunks = indices[documentID] ?? []
            for (chunk, embedding) in chunkTuples {
                let newStoredChunk = StoredChunk(embedding: embedding, content: chunk.content)
                documentChunks.append(newStoredChunk)
            }
            indices[documentID] = documentChunks
            await self.saveIndices(for: documentID)
        }
    }

    /// Adds a chunk's content and its embedding to storage.
    func addChunk(_ chunk: EmbeddableChunk, embedding: [Float]) async {
        await self.loadIndices(for: chunk.documentID)
        let documentID = chunk.documentID
        let newStoredChunk = StoredChunk(embedding: embedding, content: chunk.content)
        var documentChunks = indices[documentID] ?? []
        documentChunks.append(newStoredChunk)
        indices[documentID] = documentChunks
        await self.saveIndices(for: documentID)
    }

    /// Finds the K closest chunks to a given query EMBEDDING using cosine similarity.
    func closestChunks(documentID: UUID, to embedding: [[Float]], topK: Int) async -> [StoredChunk] {
        // Use Euclidean distance for [Float] embeddings
        guard let queryEmbedding = embedding.first, !queryEmbedding.isEmpty else {
            print("Warning: Query embedding is empty or invalid.")
            return []
        }

        await self.loadIndices(for: documentID)
        guard let storedChunks = indices[documentID], !storedChunks.isEmpty else {
            print("No indices found for documentID \(documentID)")
            return []
        }

        func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
            precondition(a.count == b.count, "Embeddings must have the same length")
            let sum = zip(a, b).map { (x, y) in (x - y) * (x - y) }.reduce(0, +)
            return sqrt(sum)
        }

        let distances = storedChunks.map { chunk -> (chunk: StoredChunk, distance: Float) in
            let distance = euclideanDistance(queryEmbedding, chunk.embedding)
            return (chunk: chunk, distance: distance)
        }

        // Sort by distance (lower is better for Euclidean distance)
        let sorted = distances.sorted { $0.distance < $1.distance }

        return Array(sorted.prefix(topK).map { $0.chunk })
    }

   

    /// Deletes all indices for the given documentID from memory and disk.
    func deleteIndices(for documentID: UUID) async {
        indices.removeValue(forKey: documentID)
        let fileURL = appDirectoryURL.appendingPathComponent(indexName(for: documentID))
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Deleted indices file for documentID \(documentID) at \(fileURL.path)")
            }
        } catch {
            print("Failed to delete indices file for documentID \(documentID): \(error)")
        }
    }

    /// Loads an array of `StoredChunk` from disk.
    private func loadIndices(for documentID: UUID) async {
        let fileURL = appDirectoryURL.appendingPathComponent(indexName(for: documentID))
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedIndices = try JSONDecoder().decode([StoredChunk].self, from: data)
            indices[documentID] = loadedIndices
        } catch {
            indices[documentID] = []
        }
    }

    /// Saves an array of `StoredChunk` to disk.
    private func saveIndices(for documentID: UUID) async {
        guard let chunks = indices[documentID] else { return }
        let fileURL = appDirectoryURL.appendingPathComponent(indexName(for: documentID))
        do {
            let data = try JSONEncoder().encode(chunks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save indices for documentID \(documentID): \(error)")
        }
    }

    /// Clears the in-memory cache of indices.
    func clearFromMemory() {
        indices.removeAll()
    }

    private func indexName(for documentID: UUID) -> String {
        return "nl_index_\(documentID.uuidString).json"
    }

    // Removed cosineSimilarity: now using Euclidean distance for retrieval
}
