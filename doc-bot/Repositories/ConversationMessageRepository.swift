import Foundation

/// Protocol for CRUD operations on ConversationMessage models.
protocol ConversationMessageRepository: BaseCrudRepository where Entity == PdfMessage {}
