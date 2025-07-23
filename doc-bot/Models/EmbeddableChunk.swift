import Foundation

struct EmbeddableChunk: Identifiable, Codable {
    let id: UUID
    let content: String
    let documentID: UUID

    init(content: String, documentID: UUID) {
        self.id = UUID()
        self.content = content
        self.documentID = documentID
    }
}


struct StoredChunk: Codable {
    let embedding: [Float]
    let content: String
}
