import Foundation

/// Protocol for CRUD operations on Conversation models.
protocol ConversationRepository: BaseCrudRepository where Entity == PdfConversation {}
