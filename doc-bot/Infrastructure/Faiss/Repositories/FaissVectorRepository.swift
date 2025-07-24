
import Foundation
import SwiftFaiss

// A new Codable struct to store both the embedding and the original text content.


class FaissVectorRepository: VectorChunkRepository {
    func closestChunks(documentID: UUID, to queryText: String, topK: Int) async -> [StoredChunk] {
        return []
    }
    
    /// Adds multiple chunks and their embeddings to storage in a single operation.
    /// - Parameter chunks: An array of tuples where each tuple contains an EmbeddableChunk and its corresponding embedding vector.
    func addChunk(_ chunks: [(EmbeddableChunk, [Float])]) async {
        
        // Group chunks by documentID for efficient batch processing
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
  
    // This is now the main storage, holding both embeddings and their content.
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
        // No need to load all indices at startup
    }

    /// Finds the K closest chunks to a given embedding and returns them.
    /// - Note: The input embedding is a single vector `[Float]`.
    func closestChunks(documentID: UUID, to embedding: [[Float]], topK: Int) async -> [StoredChunk] {
        await self.loadIndices(for: documentID)
        guard let storedChunks = indices[documentID], !storedChunks.isEmpty else {
            print("No indices found for documentID \(documentID)")
            return []
        }

        // Extract just the embeddings to build the Faiss index
        let allEmbeddings = storedChunks.map { $0.embedding }
        guard let firstEmbedding = allEmbeddings.first else { return [] }
        let d = firstEmbedding.count // Vector dimension

        do {
            let faissIndex = try FlatIndex(d: d, metricType: .l2)
            try faissIndex.add(allEmbeddings)

            // Faiss search expects a 2D array of queries, so we wrap our single embedding.
            let results = try faissIndex.search(embedding, k: topK)
            self.clearFromMemory()

            // The 'labels' are the original indices of the vectors we added.
            guard let resultIndices = results.labels.first else {
                return []
            }

            // Map the found indices back to our original StoredChunk objects.
            let foundChunks = resultIndices.compactMap { index -> StoredChunk? in
                // Faiss returns -1 for no neighbor.
                guard index != -1 && storedChunks.indices.contains(Int(index)) else {
                    return nil
                }
                return storedChunks[Int(index)]
            }

            return foundChunks

        } catch {
            self.clearFromMemory()
            print("Faiss error: \(error)")
            return []
        }
    }

    /// Adds a chunk's content and its embedding to storage.
    func addChunk(_ chunk: EmbeddableChunk, embedding: [Float]) async {
        await self.loadIndices(for: chunk.documentID)

        let documentID = chunk.documentID

        // Create the new object that holds both content and embedding.
        let newStoredChunk = StoredChunk(embedding: embedding, content: chunk.content)

        var documentChunks = indices[documentID] ?? []
        documentChunks.append(newStoredChunk)
        indices[documentID] = documentChunks

        await self.saveIndices(for: documentID)
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
            // Decode into our new [StoredChunk] type.
            let loadedIndices = try JSONDecoder().decode([StoredChunk].self, from: data)
            indices[documentID] = loadedIndices
            print("Successfully loaded indices for documentID \(documentID) from \(fileURL.path)")
        } catch {
            print("Failed to load indices for documentID \(documentID): \(error)")
            indices[documentID] = []
        }
    }

    /// Saves an array of `StoredChunk` to disk.
    private func saveIndices(for documentID: UUID) async {
        guard let chunks = indices[documentID] else { return }
        let fileURL = appDirectoryURL.appendingPathComponent(indexName(for: documentID))
        do {
            // Encode our new [StoredChunk] type.
            let data = try JSONEncoder().encode(chunks)
            try data.write(to: fileURL, options: .atomic)
            print("Successfully saved indices for documentID \(documentID) to \(fileURL.path)")
        } catch {
            print("Failed to save indices for documentID \(documentID): \(error)")
        }
    }

    /// Clears the in-memory cache of indices.
    func clearFromMemory() {
        indices.removeAll()
    }

    private func indexName(for documentID: UUID) -> String {
        return "faiss_index_\(documentID.uuidString).json"
    }
}
