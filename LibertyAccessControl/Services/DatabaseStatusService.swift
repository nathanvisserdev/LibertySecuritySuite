//
//  DatabaseStatusService.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import CoreData

struct DatabaseStatus {
    let name: String
    let location: String
    let exists: Bool
    let size: String?
    let type: DatabaseType
    
    enum DatabaseType {
        case coreData
        case encrypted
        case userDefaults
    }
}

class DatabaseStatusService {
    static let shared = DatabaseStatusService()
    
    private init() {}
    
    func checkAllDatabases() -> [DatabaseStatus] {
        var statuses: [DatabaseStatus] = []
        
        // 1. FileSystem Monitor CoreData Database
        statuses.append(checkFileSystemDatabase())
        
        // 2. Secure Notes Encrypted Database
        statuses.append(checkSecureNotesDatabase())
        
        // 3. Blacklist UserDefaults Database
        statuses.append(checkBlacklistDatabase())
        
        // 4. Monitoring Preferences UserDefaults
        statuses.append(checkPreferencesDatabase())
        
        return statuses
    }
    
    func initializeDatabases() -> [String] {
        var messages: [String] = []
        
        // Initialize FileSystem CoreData
        let _ = FileSystemPersistenceController.shared
        messages.append("✅ FileSystem Monitor database initialized")
        
        // Initialize Secure Notes (creates encryption key if needed)
        let _ = SecureNotesService.shared
        messages.append("✅ Secure Notes encryption initialized")
        
        // Initialize Blacklist Service
        let _ = BlacklistService.shared
        messages.append("✅ Blacklist database initialized")
        
        // Preferences initialized automatically via @AppStorage
        messages.append("✅ Monitoring Preferences initialized")
        
        return messages
    }
    
    // MARK: - Individual Database Checks
    
    private func checkFileSystemDatabase() -> DatabaseStatus {
        let storeURL = getFileSystemDatabaseURL()
        let exists = FileManager.default.fileExists(atPath: storeURL.path)
        let size = exists ? getFileSize(storeURL) : nil
        
        return DatabaseStatus(
            name: "FileSystem Monitor",
            location: storeURL.path,
            exists: exists,
            size: size,
            type: .coreData
        )
    }
    
    private func checkSecureNotesDatabase() -> DatabaseStatus {
        // Secure Notes uses UserDefaults with encrypted data
        let hasData = UserDefaults.standard.data(forKey: "encryptedNotes") != nil
        let location = "~/Library/Preferences/com.apple.dt.Xcode.plist (encrypted)"
        
        return DatabaseStatus(
            name: "Secure Notes",
            location: location,
            exists: hasData,
            size: hasData ? getEncryptedDataSize() : nil,
            type: .encrypted
        )
    }
    
    private func checkBlacklistDatabase() -> DatabaseStatus {
        let hasData = UserDefaults.standard.data(forKey: "blacklistedBundleIDs") != nil
        let location = "~/Library/Preferences/com.apple.dt.Xcode.plist"
        
        return DatabaseStatus(
            name: "Blacklist",
            location: location,
            exists: hasData,
            size: hasData ? getBlacklistDataSize() : nil,
            type: .userDefaults
        )
    }
    
    private func checkPreferencesDatabase() -> DatabaseStatus {
        let hasData = UserDefaults.standard.object(forKey: "enableFileSystemMonitoring") != nil
        let location = "~/Library/Preferences/com.apple.dt.Xcode.plist"
        
        return DatabaseStatus(
            name: "Monitoring Preferences",
            location: location,
            exists: hasData,
            size: nil, // Small data, size not relevant
            type: .userDefaults
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFileSystemDatabaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("com.apple.dt.Xcode")
            .appendingPathComponent("FileSystemMonitor.sqlite")
    }
    
    private func getFileSize(_ url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    private func getEncryptedDataSize() -> String? {
        guard let data = UserDefaults.standard.data(forKey: "encryptedNotes") else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
    
    private func getBlacklistDataSize() -> String? {
        guard let data = UserDefaults.standard.data(forKey: "blacklistedBundleIDs") else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
}
