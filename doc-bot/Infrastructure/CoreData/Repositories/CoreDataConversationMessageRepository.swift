import Foundation
import CoreData

/// Concrete implementation of ConversationMessageRepository using Core Data.
final class CoreDataConversationMessageRepository: ConversationMessageRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func create(entity: ChatMessage) async throws -> ChatMessage {
        let coreDataEntity = CoreDataConversationMessage(context: context)
        coreDataEntity.id = entity.id
        coreDataEntity.role = Self.roleToInt16(entity.role)
        coreDataEntity.content = entity.content
        coreDataEntity.createdAt = entity.createdAt
        coreDataEntity.updatedAt = entity.updatedAt
        coreDataEntity.conversation = try await findOrCreateConversation(entity.conversation)
        try context.save()
        return entity
    }
    
    func read(id: UUID) async throws -> ChatMessage? {
        let request = CoreDataConversationMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        let results = try context.fetch(request)
        guard let entity = results.first else { return nil }
        return Self.toPdfMessage(entity)
    }
    
    func update(entity: ChatMessage) async throws -> ChatMessage {
        let request = CoreDataConversationMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entity.id as CVarArg)
        request.fetchLimit = 1
        let results = try context.fetch(request)
        guard let coreDataEntity = results.first else { throw NSError(domain: "NotFound", code: 404) }
        coreDataEntity.role = Self.roleToInt16(entity.role)
        coreDataEntity.content = entity.content
        coreDataEntity.updatedAt = entity.updatedAt
        try context.save()
        return entity
    }
    
    func delete(id: UUID) async throws {
        let request = CoreDataConversationMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }
        try context.save()
    }
    
    func list() async throws -> [ChatMessage] {
        let request = CoreDataConversationMessage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.returnsObjectsAsFaults = false
        let entities = try context.fetch(request)
        return entities.compactMap { Self.toPdfMessage($0) }
    }
    
    // MARK: - Helpers
    static func toPdfMessage(_ entity: CoreDataConversationMessage) -> ChatMessage? {
        guard let id = entity.id,
              let content = entity.content,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt,
              let role = int16ToRole(entity.role) else { return nil }
        
        let conversation: ChatConversation? = if let conversationEntity = entity.conversation {
            CoreDataConversationRepository.toPdfConversation(conversationEntity)
        } else {
            nil
        }
        
        return ChatMessage(
            id: id,
            role: role,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            conversation: conversation
        )
    }
    
    private func findOrCreateConversation(_ conversation: ChatConversation?) async throws -> CoreDataDocumentConversation? {
        guard let conversation = conversation else { return nil }
        
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
        request.fetchLimit = 1
        
        if let existing = try context.fetch(request).first {
            return existing
        }
        
        // Create new conversation if it doesn't exist
        let coreDataEntity = CoreDataDocumentConversation(context: context)
        coreDataEntity.id = conversation.id
        coreDataEntity.subject = nil
        coreDataEntity.createdAt = conversation.createdAt
        coreDataEntity.updatedAt = conversation.updatedAt
        coreDataEntity.document = ImportedDocument.toCoreData(conversation.document, context: context)
        
        return coreDataEntity
    }
    
    private static func roleToInt16(_ role: PdfMessageRole) -> Int16 {
        switch role {
        case .user: return 0
        case .assistant: return 1
        }
    }
    
    private static func int16ToRole(_ value: Int16) -> PdfMessageRole? {
        switch value {
        case 0: return .user
        case 1: return .assistant
        default: return nil
        }
    }
    
}
