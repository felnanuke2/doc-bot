import Foundation

/// Stores chunks and uses a true vector similarity search.
class VectorRepositoryImpl: VectorChunkRepository {

    private let appDirectoryURL: URL
    
    func store(embedded: [EmbeddedChunk], for documentID: UUID) async {
        let fileURL = appDirectoryURL.appendingPathComponent("\(documentID.uuidString).json")
        print("[VectorRepositoryImpl] Storing embeddings at: \(fileURL.path)")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(embedded)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to store embeddings for documentID \(documentID): \(error)")
        }
    }

    func restoreEmbeddings(for documentID: UUID) async -> [EmbeddedChunk]? {
        let fileURL = appDirectoryURL.appendingPathComponent("\(documentID.uuidString).json")
        print("[VectorRepositoryImpl] Restoring embeddings from: \(fileURL.path)")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let embedded = try decoder.decode([EmbeddedChunk].self, from: data)
            return embedded
        } catch {
            print("Failed to restore embeddings for documentID \(documentID): \(error)")
            return nil
        }
    }
    

    
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

}
