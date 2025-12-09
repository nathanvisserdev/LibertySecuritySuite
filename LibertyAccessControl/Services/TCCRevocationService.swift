//
//  TCCRevocationService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import SQLite3

/// Service to handle complete TCC permission revocation including cache invalidation
class TCCRevocationService {
    
    static let shared = TCCRevocationService()
    
    private let cacheInterceptService = CacheInterceptService.shared
    private let blacklistService = BlacklistService.shared
    
    private init() {}
    
    // MARK: - User TCC Revocation
    
    /// Revoke a user-level TCC permission with full cache invalidation
    func revokeUserPermission(
        service: String,
        client: String,
        bundleID: String?,
        teamID: String?,
        reason: String? = nil,
        completion: @escaping (Bool, String) -> Void
    ) {
        print("🔄 Starting user TCC revocation for \(client) - \(service)")
        
        // Step 1: Kill tccd and intercept cache
        guard let targetBundleID = bundleID else {
            // If no bundle ID, try to extract from client path
            let extractedBundleID = extractBundleIDFromClient(client)
            if let bundleId = extractedBundleID {
                performRevocation(
                    databasePath: getUserTCCPath(),
                    service: service,
                    client: client,
                    bundleID: bundleId,
                    teamID: teamID,
                    reason: reason,
                    isSystemDB: false,
                    completion: completion
                )
            } else {
                completion(false, "Cannot revoke: Bundle ID required for cache invalidation")
            }
            return
        }
        
        performRevocation(
            databasePath: getUserTCCPath(),
            service: service,
            client: client,
            bundleID: targetBundleID,
            teamID: teamID,
            reason: reason,
            isSystemDB: false,
            completion: completion
        )
    }
    
    // MARK: - System TCC Revocation
    
    /// Revoke a system-level TCC permission with full cache invalidation
    func revokeSystemPermission(
        service: String,
        client: String,
        bundleID: String?,
        teamID: String?,
        reason: String? = nil,
        completion: @escaping (Bool, String) -> Void
    ) {
        print("🔄 Starting system TCC revocation for \(client) - \(service)")
        
        guard let targetBundleID = bundleID else {
            let extractedBundleID = extractBundleIDFromClient(client)
            if let bundleId = extractedBundleID {
                performRevocation(
                    databasePath: getSystemTCCPath(),
                    service: service,
                    client: client,
                    bundleID: bundleId,
                    teamID: teamID,
                    reason: reason,
                    isSystemDB: true,
                    completion: completion
                )
            } else {
                completion(false, "Cannot revoke: Bundle ID required for cache invalidation")
            }
            return
        }
        
        performRevocation(
            databasePath: getSystemTCCPath(),
            service: service,
            client: client,
            bundleID: targetBundleID,
            teamID: teamID,
            reason: reason,
            isSystemDB: true,
            completion: completion
        )
    }
    
    // MARK: - Core Revocation Logic
    
    private func performRevocation(
        databasePath: String,
        service: String,
        client: String,
        bundleID: String,
        teamID: String?,
        reason: String?,
        isSystemDB: Bool,
        completion: @escaping (Bool, String) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Step 1: Intercept tccd cache and mark app for revocation
            print("📋 Step 1: Intercepting tccd cache for \(bundleID)...")
            self.cacheInterceptService.restartTCCDWithInterception(targetBundleId: bundleID) { result in
                switch result {
                case .success(let cacheInfo):
                    print("✅ Cache intercepted:\n\(cacheInfo)")
                    
                    // Step 2: Update TCC database to revoke permission
                    print("📋 Step 2: Updating TCC database...")
                    self.updateTCCDatabase(
                        databasePath: databasePath,
                        service: service,
                        client: client,
                        isSystemDB: isSystemDB
                    ) { dbSuccess, dbMessage in
                        
                        if dbSuccess {
                            // Step 3: Add to blacklist
                            print("📋 Step 3: Adding to blacklist...")
                            self.blacklistService.addToBlacklist(
                                service: service,
                                client: client,
                                bundleID: bundleID,
                                teamID: teamID,
                                reason: reason
                            )
                            
                            self.blacklistService.logRevocationAttempt(
                                service: service,
                                client: client,
                                bundleID: bundleID,
                                blocked: false
                            )
                            
                            // Step 4: Restart tccd normally (without hook)
                            print("📋 Step 4: Restarting tccd normally...")
                            self.restartTCCDNormally()
                            
                            DispatchQueue.main.async {
                                completion(true, "✅ Permission revoked successfully\n\n🔐 Cache invalidated for \(bundleID)\n💾 Database updated\n🚫 Added to blacklist\n\nThe app will need to request permission again, but it will be denied.")
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(false, "Failed to update TCC database: \(dbMessage)")
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Failed to intercept cache: \(error.localizedDescription)")
                    // Try to revoke without cache interception
                    print("⚠️ Attempting database-only revocation...")
                    
                    self.updateTCCDatabase(
                        databasePath: databasePath,
                        service: service,
                        client: client,
                        isSystemDB: isSystemDB
                    ) { dbSuccess, dbMessage in
                        if dbSuccess {
                            self.blacklistService.addToBlacklist(
                                service: service,
                                client: client,
                                bundleID: bundleID,
                                teamID: teamID,
                                reason: reason
                            )
                            
                            DispatchQueue.main.async {
                                completion(true, "⚠️ Permission revoked (cache not invalidated)\n\n💾 Database updated\n🚫 Added to blacklist\n\nNote: Cache interception failed. The app may still have cached access until tccd restarts.")
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(false, "Failed: \(dbMessage)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Database Operations
    
    private func updateTCCDatabase(
        databasePath: String,
        service: String,
        client: String,
        isSystemDB: Bool,
        completion: @escaping (Bool, String) -> Void
    ) {
        var db: OpaquePointer?
        
        // Open database with write access
        let flags = SQLITE_OPEN_READWRITE
        let result = sqlite3_open_v2(databasePath, &db, flags, nil)
        
        guard result == SQLITE_OK, let database = db else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            completion(false, "Cannot open database: \(errorMsg)")
            return
        }
        
        defer { sqlite3_close(database) }
        
        // Option 1: Delete the entry entirely (cleaner revocation)
        let deleteQuery = "DELETE FROM access WHERE service = ? AND client = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, deleteQuery, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(database))
            completion(false, "Failed to prepare statement: \(errorMsg)")
            return
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, service, -1, nil)
        sqlite3_bind_text(statement, 2, client, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_DONE {
            let changes = sqlite3_changes(database)
            print("✅ Deleted \(changes) row(s) from TCC database")
            completion(true, "Database updated: \(changes) row(s) deleted")
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(database))
            completion(false, "Failed to delete: \(errorMsg)")
        }
        
        // Alternative: Update to denied (auth_value = 0)
        // This keeps a record of the denial
        /*
        let updateQuery = "UPDATE access SET auth_value = 0, auth_reason = 3 WHERE service = ? AND client = ?"
        // auth_value = 0 means denied
        // auth_reason = 3 means denied by user
        */
    }
    
    // MARK: - Helper Methods
    
    private func getUserTCCPath() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(homeDir)/Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    private func getSystemTCCPath() -> String {
        return "/Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    private func extractBundleIDFromClient(_ client: String) -> String? {
        // Try to extract bundle ID from client path
        // e.g., "/Applications/Slack.app" -> "com.tinyspeck.slackmacgap"
        
        if client.hasSuffix(".app") {
            // This is an app bundle path, try to read Info.plist
            let infoPlistPath = "\(client)/Contents/Info.plist"
            if let plistData = FileManager.default.contents(atPath: infoPlistPath),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
               let bundleID = plist["CFBundleIdentifier"] as? String {
                return bundleID
            }
        }
        
        // If client already looks like a bundle ID, use it
        if client.contains(".") && !client.contains("/") {
            return client
        }
        
        return nil
    }
    
    private func restartTCCDNormally() {
        // Kill tccd and let macOS restart it naturally
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = ["tccd"]
        
        try? task.run()
        task.waitUntilExit()
        
        print("🔄 tccd killed, will restart automatically")
    }
}
