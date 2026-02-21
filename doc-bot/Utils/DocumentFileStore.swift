import Foundation

enum DocumentFileStore {
    private static let directoryName = "documents"

    static func storeDocument(from fileURL: URL, documentId: UUID) throws -> URL {
        let destinationURL = documentURL(for: documentId)
        let directoryURL = destinationURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        return destinationURL
    }

    static func documentURL(for documentId: UUID) -> URL {
        let baseURL = applicationSupportDirectory()
        return baseURL
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent("\(documentId.uuidString).pdf")
    }

    static func storedDocumentURL(for documentId: UUID) -> URL? {
        let url = documentURL(for: documentId)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func applicationSupportDirectory() -> URL {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Could not find Application Support directory.")
        }
        let appDirectoryURL = url.appendingPathComponent(Bundle.main.bundleIdentifier ?? "doc-bot")
        if !FileManager.default.fileExists(atPath: appDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true)
        }
        return appDirectoryURL
    }
}
