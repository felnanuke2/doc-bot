import Foundation
import CoreData

/// Concrete implementation of ConversationRepository using Core Data.
final class CoreDataConversationRepository: ConversationRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create(entity: ChatConversation) async throws -> ChatConversation {
        let coreDataEntity = CoreDataDocumentConversation(context: context)
        coreDataEntity.id = entity.id
        coreDataEntity.subject = entity.subject
        coreDataEntity.createdAt = entity.createdAt
        coreDataEntity.updatedAt = entity.updatedAt
        coreDataEntity.document = ImportedDocument.toCoreData(entity.document, context: context)
        try context.save()
        return entity
    }

    func read(id: UUID) async throws -> ChatConversation? {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        // Prefetch relationships to avoid lazy loading issues
        request.relationshipKeyPathsForPrefetching = ["messages", "document"]
        let results = try context.fetch(request)
        guard let entity = results.first else { return nil }
        return ChatConversation.from(coreData: entity)
    }

    func update(entity: ChatConversation) async throws -> ChatConversation {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entity.id as CVarArg)
        request.fetchLimit = 1
        let results = try context.fetch(request)
        guard let coreDataEntity = results.first else { throw NSError(domain: "NotFound", code: 404) }
        coreDataEntity.subject = entity.subject
        coreDataEntity.updatedAt = entity.updatedAt
        try context.save()
        return entity
    }

    func delete(id: UUID) async throws {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        
        guard !results.isEmpty else {
            throw NSError(domain: "ConversationNotFound", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Conversation with ID \(id) not found"
            ])
        }
        
        for entity in results {
            // With Cascade deletion rule, messages will be automatically deleted
            context.delete(entity)
        }
        
        try context.save()
    }

    func list() async throws -> [ChatConversation] {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.returnsObjectsAsFaults = false
        let entities = try context.fetch(request)
        return entities.compactMap { Self.toPdfConversation($0) }
    }
    
    func conversationsForDocument(documentId: UUID) async throws -> [ChatConversation] {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "document.id == %@", documentId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.returnsObjectsAsFaults = false
        // Prefetch relationships to avoid lazy loading issues
        request.relationshipKeyPathsForPrefetching = ["messages", "document"]
        let entities = try context.fetch(request)
        
        return entities.compactMap { entity in
            ChatConversation.from(coreData: entity)
        }
    }

    // MARK: - Helpers
    static func toPdfConversation(_ entity: CoreDataDocumentConversation) -> ChatConversation? {
        guard let id = entity.id,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt,
              let document = entity.document
        else { return nil }
        // messages is required, but not mapped here. Use empty array for now.
        return ChatConversation(
            id: id,
            messages: [],
            subject: entity.subject,
            createdAt: createdAt,
            updatedAt: updatedAt,
            document: ImportedDocument.from(coreData: document)
        )
    }
}
