import Foundation
import CoreData

extension ChatConversation {
    static func from(coreData: CoreDataDocumentConversation, includeDocument: Bool = true) -> ChatConversation {
        // Map messages from Core Data
        let messages = (coreData.messages?.allObjects as? [CoreDataConversationMessage])?.compactMap { coreDataMessage in
            ChatMessage.from(coreData: coreDataMessage, includeConversation: false)
        } ?? []
        
        // Map the document (avoiding circular reference by optionally including it)
        let document = includeDocument ? ImportedDocument.from(coreData: coreData.document!, includeConversations: false) : ImportedDocument(
            id: coreData.document?.id,
            name: coreData.document?.name,
            conversations: nil, // Avoid circular reference
            createdAt: coreData.document?.createdAt,
            updatedAt: coreData.document?.updatedAt
        )
        
        return ChatConversation(
            id: coreData.id ?? UUID(),
            messages: messages,
            subject: coreData.subject,
            createdAt: coreData.createdAt ?? Date(),
            updatedAt: coreData.updatedAt ?? Date(),
            document: document
        )
    }
    
    static func toCoreData(_ conversation: ChatConversation, context: NSManagedObjectContext) -> CoreDataDocumentConversation? {
        // First try to find existing conversation
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
        request.fetchLimit = 1
        
        if let existingConversation = try? context.fetch(request).first {
            // Update existing conversation
            existingConversation.subject = conversation.subject
            existingConversation.updatedAt = conversation.updatedAt
            return existingConversation
        }
        
        // If not found, create a new one
        let coreDataConversation = CoreDataDocumentConversation(context: context)
        coreDataConversation.id = conversation.id
        coreDataConversation.subject = conversation.subject
        coreDataConversation.createdAt = conversation.createdAt
        coreDataConversation.updatedAt = conversation.updatedAt
        
        return coreDataConversation
    }
}