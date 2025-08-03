import Foundation

protocol BaseModel: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

struct ImportedDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID?
    let name: String?
    var conversations: [ChatConversation]?
    let createdAt: Date?
    let updatedAt: Date?
}

struct ChatConversation: BaseModel {
    let id: UUID
    var messages: [ChatMessage]
    var subject: String?
    let createdAt: Date
    let updatedAt: Date
    let document: ImportedDocument
}


struct ChatMessage: BaseModel {
    let id: UUID
    let role: PdfMessageRole
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let conversation: ChatConversation?
}

enum PdfMessageRole: String, Codable, Equatable {
    case user
    case assistant
}
