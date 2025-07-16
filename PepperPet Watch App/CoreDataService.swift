//
//  CoreDataService.swift
//  PepperPet
//
//  Created by Daniel Rangel on 7/15/25.
//

import CoreData
import Foundation

/// Core Data service with proper error handling and watchOS optimization
class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    // MARK: - Error Types
    enum CoreDataError: Error, LocalizedError {
        case persistentStoreLoadingFailed(Error)
        case contextSaveFailed(Error)
        case fetchFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .persistentStoreLoadingFailed(let error):
                return "Failed to load persistent store: \(error.localizedDescription)"
            case .contextSaveFailed(let error):
                return "Failed to save context: \(error.localizedDescription)"
            case .fetchFailed(let error):
                return "Failed to fetch data: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        // Fixed: Use correct model name "Pet" instead of "PepperPetModel"
        let container = NSPersistentContainer(name: "Pet")
        
        // Configure for watchOS optimization
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.shouldInferMappingModelAutomatically = true
        
        // Enable persistent history tracking for future CloudKit integration
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                // Log error but don't crash - graceful degradation
                print("⚠️ CoreData Error: \(CoreDataError.persistentStoreLoadingFailed(error).localizedDescription)")
                
                // Could implement fallback to in-memory store here
                self?.createInMemoryFallbackStore(container: container)
            }
        }
        
        // Auto-merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// Main context for UI operations (always on main queue)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Core Operations
    
    /// Save context with proper error handling
    @discardableResult
    func save() -> Result<Void, CoreDataError> {
        guard viewContext.hasChanges else { return .success(()) }
        
        do {
            try viewContext.save()
            return .success(())
        } catch {
            return .failure(.contextSaveFailed(error))
        }
    }
    
    /// Background save operation
    func saveInBackground(_ operation: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = newBackgroundContext()
        
        backgroundContext.perform {
            operation(backgroundContext)
            
            do {
                try backgroundContext.save()
            } catch {
                print("⚠️ Background save failed: \(error)")
            }
        }
    }
    
    // MARK: - Fallback Store
    private func createInMemoryFallbackStore(container: NSPersistentContainer) {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in
            print("📝 Using in-memory fallback store")
        }
    }
}
