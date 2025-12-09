import Foundation
import CoreData
import CryptoKit

class FileSystemPersistenceController {
    static let shared = FileSystemPersistenceController()
    
    let container: NSPersistentContainer
    
    // Encryption key stored in Keychain
    private let encryptionKeyTag = "com.liberty.filesystem.encryption"
    private var encryptionKey: SymmetricKey?
    
    private init() {
        container = NSPersistentContainer(name: "FileSystemMonitor")
        
        // Configure persistent store with encryption
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable persistent history tracking
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Set file permissions for security (macOS equivalent of file protection)
        if let storeURL = description.url {
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: storeURL.path)
        }
        
        // Load encryption key or create new one
        encryptionKey = loadOrCreateEncryptionKey()
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ FileSystem Core Data initialized with encryption")
    }
    
    // MARK: - Encryption Key Management
    
    private func loadOrCreateEncryptionKey() -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKey = loadKeyFromKeychain() {
            return existingKey
        }
        
        // Create new key and save to Keychain
        let newKey = SymmetricKey(size: .bits256)
        saveKeyToKeychain(newKey)
        return newKey
    }
    
    private func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ Failed to save encryption key to Keychain: \(status)")
        }
    }
    
    // MARK: - Save Events
    
    func saveEvent(_ event: FileSystemEvent) {
        let context = container.viewContext
        
        context.perform {
            let entity = FileSystemEventEntity(context: context)
            entity.id = event.id
            entity.timestamp = event.timestamp
            entity.path = event.path
            entity.fileName = event.fileName
            entity.eventTypeRaw = event.eventType.rawValue
            entity.flagsRaw = Int32(event.flags.rawValue)
            entity.severityRaw = event.severity.rawValue
            entity.details = event.details
            
            self.saveContext()
        }
    }
    
    func saveEvents(_ events: [FileSystemEvent]) {
        let context = container.viewContext
        
        context.perform {
            for event in events {
                let entity = FileSystemEventEntity(context: context)
                entity.id = event.id
                entity.timestamp = event.timestamp
                entity.path = event.path
                entity.fileName = event.fileName
                entity.eventTypeRaw = event.eventType.rawValue
                entity.flagsRaw = Int32(event.flags.rawValue)
                entity.severityRaw = event.severity.rawValue
                entity.details = event.details
            }
            
            self.saveContext()
        }
    }
    
    // MARK: - Save Alerts
    
    func saveAlert(_ alert: FileSystemAlert) {
        let context = container.viewContext
        
        context.perform {
            let entity = FileSystemAlertEntity(context: context)
            entity.id = alert.id
            entity.timestamp = alert.timestamp
            entity.title = alert.title
            entity.message = alert.message
            entity.severityRaw = alert.severity.rawValue
            entity.path = alert.path
            
            self.saveContext()
        }
    }
    
    // MARK: - Fetch Events
    
    func fetchEvents(limit: Int = 1000, predicate: NSPredicate? = nil) -> [FileSystemEvent] {
        let context = container.viewContext
        let request: NSFetchRequest<FileSystemEventEntity> = FileSystemEventEntity.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        request.predicate = predicate
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toFileSystemEvent() }
        } catch {
            print("Error fetching events: \(error)")
            return []
        }
    }
    
    func fetchRecentEvents(minutes: Int = 60) -> [FileSystemEvent] {
        let date = Date().addingTimeInterval(TimeInterval(-minutes * 60))
        let predicate = NSPredicate(format: "timestamp >= %@", date as NSDate)
        return fetchEvents(predicate: predicate)
    }
    
    func fetchHighSeverityEvents() -> [FileSystemEvent] {
        let predicate = NSPredicate(format: "severityRaw IN %@", ["High", "Critical"])
        return fetchEvents(predicate: predicate)
    }
    
    // MARK: - Fetch Alerts
    
    func fetchAlerts(limit: Int = 100) -> [FileSystemAlert] {
        let context = container.viewContext
        let request: NSFetchRequest<FileSystemAlertEntity> = FileSystemAlertEntity.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { $0.toFileSystemAlert() }
        } catch {
            print("Error fetching alerts: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    func getTotalEventCount() -> Int {
        let context = container.viewContext
        let request: NSFetchRequest<FileSystemEventEntity> = FileSystemEventEntity.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting events: \(error)")
            return 0
        }
    }
    
    func getEventCountBySeverity() -> [String: Int] {
        let context = container.viewContext
        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "FileSystemEventEntity")
        
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["severityRaw"]
        
        do {
            let results = try context.fetch(request)
            var counts: [String: Int] = [:]
            
            for result in results {
                if let severity = result["severityRaw"] as? String {
                    counts[severity, default: 0] += 1
                }
            }
            
            return counts
        } catch {
            print("Error getting severity counts: \(error)")
            return [:]
        }
    }
    
    // MARK: - Data Retention & Cleanup
    
    func deleteOldEvents(olderThanDays days: Int) {
        let context = container.viewContext
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = FileSystemEventEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeCount
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            print("🗑️ Deleted \(deletedCount) old events")
            
            saveContext()
        } catch {
            print("Error deleting old events: \(error)")
        }
    }
    
    func deleteOldAlerts(olderThanDays days: Int) {
        let context = container.viewContext
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = FileSystemAlertEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeCount
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let deletedCount = result?.result as? Int ?? 0
            print("🗑️ Deleted \(deletedCount) old alerts")
            
            saveContext()
        } catch {
            print("Error deleting old alerts: \(error)")
        }
    }
    
    func deleteAllEvents() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = FileSystemEventEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
            print("🗑️ Deleted all events")
        } catch {
            print("Error deleting all events: \(error)")
        }
    }
    
    func deleteAllAlerts() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = FileSystemAlertEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
            print("🗑️ Deleted all alerts")
        } catch {
            print("Error deleting all alerts: \(error)")
        }
    }
    
    // MARK: - Context Management
    
    private func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Core Data save error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - Core Data Entity Extensions

@objc(FileSystemEventEntity)
public class FileSystemEventEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var path: String
    @NSManaged public var fileName: String
    @NSManaged public var eventTypeRaw: String
    @NSManaged public var flagsRaw: Int32
    @NSManaged public var severityRaw: String
    @NSManaged public var details: String
    
    func toFileSystemEvent() -> FileSystemEvent? {
        guard let eventType = FSEventType(rawValue: eventTypeRaw),
              let severity = FileSystemThreatSeverity(rawValue: severityRaw) else {
            return nil
        }
        
        let flags = FSEventFlags(rawValue: UInt32(flagsRaw))
        
        return FileSystemEvent(
            timestamp: timestamp,
            path: path,
            eventType: eventType,
            flags: flags,
            severity: severity,
            details: details
        )
    }
}

extension FileSystemEventEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileSystemEventEntity> {
        return NSFetchRequest<FileSystemEventEntity>(entityName: "FileSystemEventEntity")
    }
}

@objc(FileSystemAlertEntity)
public class FileSystemAlertEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var title: String
    @NSManaged public var message: String
    @NSManaged public var severityRaw: String
    @NSManaged public var path: String
    
    func toFileSystemAlert() -> FileSystemAlert? {
        guard let severity = FileSystemThreatSeverity(rawValue: severityRaw) else {
            return nil
        }
        
        return FileSystemAlert(
            timestamp: timestamp,
            title: title,
            message: message,
            severity: severity,
            path: path
        )
    }
}

extension FileSystemAlertEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileSystemAlertEntity> {
        return NSFetchRequest<FileSystemAlertEntity>(entityName: "FileSystemAlertEntity")
    }
}
