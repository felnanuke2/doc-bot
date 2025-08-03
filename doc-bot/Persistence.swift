//
//  Persistence.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 20/07/25.
//

import CoreData
import CoreTransferable

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews if needed
        // For example:
        // let newItem = Item(context: viewContext)
        // newItem.timestamp = Date()
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "doc_bot")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure persistent store description
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error details for debugging
                print("❌ Core Data error: \(error)")
                print("❌ Error info: \(error.userInfo)")
                
                // In development, you might want to delete the store and recreate it
                // For production, handle this more gracefully
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Print Core Data database path for debugging/browsing
            if let storeURL = storeDescription.url {
                print("📊 Core Data Database Path: \(storeURL.path)")
                print("📊 You can browse this database using tools like DB Browser for SQLite")
                print("📊 Store type: \(storeDescription.type)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Helper Methods
    
    /// Safely save the view context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("❌ Failed to save context: \(nsError), \(nsError.userInfo)")
                // Handle the error appropriately - don't crash in production
                #if DEBUG
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                #endif
            }
        }
    }
    
    /// Reset the Core Data store (useful for development/debugging)
    func resetStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("❌ No store URL found")
            return
        }
        
        do {
            // Remove the existing store
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("📊 Core Data store reset successfully")
            }
        } catch {
            print("❌ Failed to reset store: \(error)")
        }
    }
}
