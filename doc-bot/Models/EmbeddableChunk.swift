import Foundation

struct EmbeddableChunk: Identifiable, Codable {
    let id: UUID
    let documentID: UUID
    let documentChunk: DocumentChunk

    var content: String {
        documentChunk.text
    }

    init(documentChunk: DocumentChunk, documentID: UUID, id: UUID = UUID()) {
        self.id = id
        self.documentID = documentID
        self.documentChunk = documentChunk
    }

    init(content: String, documentID: UUID, pageNumber: Int = 0) {
        self.init(documentChunk: DocumentChunk(text: content, pageNumber: pageNumber), documentID: documentID)
    }
}

class EmbeddedChunk: Codable {
    let id: UUID
    let documentID: UUID
    let documentChunk: DocumentChunk
    var embedding: [Double]?

    var content: String {
        documentChunk.text
    }

    init(id: UUID, documentChunk: DocumentChunk, documentID: UUID) {
        self.id = id
        self.documentChunk = documentChunk
        self.documentID = documentID
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case documentID
        case documentChunk
        case content
        case embedding
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.documentID = try container.decode(UUID.self, forKey: .documentID)
        if let chunk = try container.decodeIfPresent(DocumentChunk.self, forKey: .documentChunk) {
            self.documentChunk = chunk
        } else {
            let content = try container.decode(String.self, forKey: .content)
            self.documentChunk = DocumentChunk(text: content, pageNumber: 0)
        }
        self.embedding = try container.decodeIfPresent([Double].self, forKey: .embedding)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(documentID, forKey: .documentID)
        try container.encode(documentChunk, forKey: .documentChunk)
        try container.encodeIfPresent(embedding, forKey: .embedding)
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
        EmbeddedChunk(id: id, documentChunk: documentChunk, documentID: documentID)
    }
}
