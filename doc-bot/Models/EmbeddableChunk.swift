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

class EmbeddedChunk: Codable {
    let id: UUID
    let documentID: UUID
    let content: String
    var embedding: [Double]?
    
    init(id: UUID, content: String, documentID: UUID){
        self.id = id
        self.content = content
        self.documentID = documentID
    }
}

/// Custom errors for the NaturalLanguage embedding repository
enum EmbeddingError: Error {
    case noEmbeddingAvailable
    case noWordsFound
    case invalidText
    
    var localizedDescription: String {
        switch self {
        case .noEmbeddingAvailable:
            return "No embedding model available for the specified language"
        case .noWordsFound:
            return "No valid words found in the input text"
        case .invalidText:
            return "The input text is invalid or empty"
        }
    }
}

extension EmbeddableChunk {
    var embeddedChunk: EmbeddedChunk {
        EmbeddedChunk(id: id, content: content, documentID: documentID)
    }
}
