import Foundation

/// Protocol for CRUD operations on Conversation models.
protocol ConversationRepository: BaseCrudRepository where Entity == ChatConversation {
    func conversationsForDocument(documentId: UUID) async throws -> [ChatConversation]
}
