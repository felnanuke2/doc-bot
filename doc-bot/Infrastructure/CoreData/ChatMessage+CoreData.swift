import Foundation
import CoreData

extension ChatMessage {
    static func from(coreData: CoreDataConversationMessage, includeConversation: Bool = true) -> ChatMessage {
        // Map the conversation (avoiding circular reference by optionally including it)
        let conversation: ChatConversation? = includeConversation && coreData.conversation != nil ? 
            ChatConversation.from(coreData: coreData.conversation!, includeDocument: false) : nil
        
        return ChatMessage(
            id: coreData.id ?? UUID(),
            role: PdfMessageRole(rawValue: coreData.role == 0 ? "user" : "assistant") ?? .user,
            content: coreData.content ?? "",
            createdAt: coreData.createdAt ?? Date(),
            updatedAt: coreData.updatedAt ?? Date(),
            conversation: conversation
        )
    }
    
    static func toCoreData(_ message: ChatMessage, context: NSManagedObjectContext) -> CoreDataConversationMessage? {
        // First try to find existing message
        let request = CoreDataConversationMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", message.id as CVarArg)
        request.fetchLimit = 1
        
        if let existingMessage = try? context.fetch(request).first {
            // Update existing message
            existingMessage.content = message.content
            existingMessage.role = message.role == .user ? 0 : 1
            existingMessage.updatedAt = message.updatedAt
            return existingMessage
        }
        
        // If not found, create a new one
        let coreDataMessage = CoreDataConversationMessage(context: context)
        coreDataMessage.id = message.id
        coreDataMessage.content = message.content
        coreDataMessage.role = message.role == .user ? 0 : 1
        coreDataMessage.createdAt = message.createdAt
        coreDataMessage.updatedAt = message.updatedAt
        
        return coreDataMessage
    }
}
