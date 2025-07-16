import CoreData
import CloudKit
import SwiftUI

/// Core Data stack with CloudKit integration for Pepper Pet
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Pet")
        
        // Configure for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        // Enable automatic merging of changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    init() {
        setupCloudKitNotifications()
    }
    
    // MARK: - CloudKit Setup
    
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: context
        )
    }
    
    @objc private func managedObjectContextDidSave(notification: Notification) {
        // Handle CloudKit sync status updates here if needed
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError.localizedDescription)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
}
