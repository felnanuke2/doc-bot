import Foundation

protocol BaseModel: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

struct ImportedDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    var conversations: [PdfConversation]
    let createdAt: Date
    let updatedAt: Date
}

struct PdfConversation: BaseModel {
    let id: UUID
    var messages: [PdfMessage]
    let createdAt: Date
    let updatedAt: Date
}


struct PdfMessage: BaseModel {
    let id: UUID
    let role: PdfMessageRole
    let content: String
    let createdAt: Date
    let updatedAt: Date
}

enum PdfMessageRole: String, Codable, Equatable {
    case user
    case assistant
}
