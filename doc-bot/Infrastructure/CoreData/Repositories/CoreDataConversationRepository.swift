import Foundation
import CoreData

/// Concrete implementation of ConversationRepository using Core Data.
final class CoreDataConversationRepository: ConversationRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create(entity: PdfConversation) async throws -> PdfConversation {
        let coreDataEntity = CoreDataDocumentConversation(context: context)
        coreDataEntity.id = entity.id
        coreDataEntity.subject = nil // PdfConversation has no title/subject property
        coreDataEntity.createdAt = entity.createdAt
        coreDataEntity.updatedAt = entity.updatedAt
        try context.save()
        return entity
    }

    func read(id: UUID) async throws -> PdfConversation? {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        let results = try context.fetch(request)
        guard let entity = results.first else { return nil }
        return Self.toPdfConversation(entity)
    }

    func update(entity: PdfConversation) async throws -> PdfConversation {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entity.id as CVarArg)
        request.fetchLimit = 1
        let results = try context.fetch(request)
        guard let coreDataEntity = results.first else { throw NSError(domain: "NotFound", code: 404) }
        coreDataEntity.subject = nil // PdfConversation has no title/subject property
        coreDataEntity.updatedAt = entity.updatedAt
        try context.save()
        return entity
    }

    func delete(id: UUID) async throws {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }
        try context.save()
    }

    func list() async throws -> [PdfConversation] {
        let request = CoreDataDocumentConversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.returnsObjectsAsFaults = false
        let entities = try context.fetch(request)
        return entities.compactMap { Self.toPdfConversation($0) }
    }

    // MARK: - Helpers
    private static func toPdfConversation(_ entity: CoreDataDocumentConversation) -> PdfConversation? {
        guard let id = entity.id,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else { return nil }
        // messages is required, but not mapped here. Use empty array for now.
        return PdfConversation(
            id: id,
            messages: [],
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
