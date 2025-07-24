import Foundation

extension ImportedDocument {
    static func from(coreData: CoreDataImportedDocument) -> ImportedDocument {
        ImportedDocument(
            id: coreData.id,
            name: coreData.name,
            conversations: [], // You can map conversations if needed
            createdAt: coreData.createdAt,
            updatedAt: coreData.updatedAt
        )
    }
}
