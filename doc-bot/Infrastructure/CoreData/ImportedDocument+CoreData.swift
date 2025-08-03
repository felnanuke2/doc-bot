import Foundation
import CoreData

extension ImportedDocument {
    static func from(coreData: CoreDataImportedDocument, includeConversations: Bool = true) -> ImportedDocument {
        // Map conversations from Core Data only if requested (to avoid circular references)
        let conversations = includeConversations ? 
            (coreData.conversations?.allObjects as? [CoreDataDocumentConversation])?.compactMap { coreDataConversation in
                // Create conversation without loading the document again to avoid circular reference
                ChatConversation.from(coreData: coreDataConversation, includeDocument: false)
            } ?? [] : nil
        
        return ImportedDocument(
            id: coreData.id,
            name: coreData.name,
            conversations: conversations,
            createdAt: coreData.createdAt,
            updatedAt: coreData.updatedAt
        )
    }
    
    static func toCoreData(_ document: ImportedDocument, context: NSManagedObjectContext) -> CoreDataImportedDocument? {
        guard let documentId = document.id else { return nil }
        
        // First try to find existing document
        let request = CoreDataImportedDocument.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)
        request.fetchLimit = 1
        
        if let existingDocument = try? context.fetch(request).first {
            return existingDocument
        }
        
        // If not found, create a new one
        let coreDataDocument = CoreDataImportedDocument(context: context)
        coreDataDocument.id = document.id
        coreDataDocument.name = document.name
        coreDataDocument.createdAt = document.createdAt
        coreDataDocument.updatedAt = document.updatedAt
        
        return coreDataDocument
    }
}
