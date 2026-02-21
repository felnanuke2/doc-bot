import Foundation

struct DocumentTextRange: Codable, Hashable {
    let location: Int
    let length: Int

    var nsRange: NSRange {
        NSRange(location: location, length: length)
    }

    static func from(_ range: NSRange) -> DocumentTextRange {
        DocumentTextRange(location: range.location, length: range.length)
    }
}

struct DocumentChunk: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let pageNumber: Int
    let boundingBox: DocumentTextRange?

    init(id: UUID = UUID(), text: String, pageNumber: Int, boundingBox: DocumentTextRange? = nil) {
        self.id = id
        self.text = text
        self.pageNumber = pageNumber
        self.boundingBox = boundingBox
    }
}

struct DocumentPageContent: Codable, Hashable {
    let pageNumber: Int
    let text: String
}
