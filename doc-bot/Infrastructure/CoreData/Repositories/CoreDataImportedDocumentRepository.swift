import Foundation
import CoreData

/// Core Data implementation of ImportedDocumentRepository
final class CoreDataImportedDocumentRepository: ImportedDocumentRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func create(entity: ImportedDocument) async throws -> ImportedDocument {
        return try await context.perform {
            let coreDataEntity = CoreDataImportedDocument(context: self.context)
            coreDataEntity.id = entity.id
            coreDataEntity.name = entity.name
            coreDataEntity.createdAt = entity.createdAt
            coreDataEntity.updatedAt = entity.updatedAt
            // Handle conversations serialization if needed
            try self.context.save()
            return entity
        }
    }
    
    func read(id: UUID) async throws -> ImportedDocument? {
        return try await context.perform {
            let request = CoreDataImportedDocument.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            let results = try self.context.fetch(request)
            guard let entity = results.first else { return nil }
            return ImportedDocument(
                id: entity.id!,
                name: entity.name ?? "",
                conversations: [], // Deserialize if needed
                createdAt: entity.createdAt ?? Date(),
                updatedAt: entity.updatedAt ?? Date()
            )
        }
    }
    
    func update(entity: ImportedDocument) async throws -> ImportedDocument {
        return try await context.perform {
            let request = CoreDataImportedDocument.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entity.id! as CVarArg)
            request.fetchLimit = 1
            let results = try self.context.fetch(request)
            guard let coreDataEntity = results.first else { 
                throw NSError(domain: "NotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "ImportedDocument with id \(entity.id) not found"]) 
            }
            coreDataEntity.name = entity.name
            coreDataEntity.updatedAt = entity.updatedAt
            // Handle conversations serialization if needed
            try self.context.save()
            return entity
        }
    }
    
    func delete(id: UUID) async throws {
        try await context.perform {
            let request = CoreDataImportedDocument.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let results = try self.context.fetch(request)
            for entity in results {
                self.context.delete(entity)
            }
            try self.context.save()
        }
    }
    
    func list() async throws -> [ImportedDocument] {
        return try await context.perform {
            let request = CoreDataImportedDocument.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.returnsObjectsAsFaults = false
            let entities = try self.context.fetch(request)
            return entities.map { entity in
                ImportedDocument(
                    id: entity.id!,
                    name: entity.name ?? "",
                    conversations: [], // Deserialize if needed
                    createdAt: entity.createdAt ?? Date(),
                    updatedAt: entity.updatedAt ?? Date()
                )
            }
        }
    }
}

// NOTE: You must define ImportedDocumentEntity in your Core Data model with matching fields.
// For full support, you should also serialize/deserialize the conversations property as needed.
