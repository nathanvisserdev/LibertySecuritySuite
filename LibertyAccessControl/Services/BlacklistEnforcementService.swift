//
//  BlacklistEnforcementService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import SQLite3
import Combine

class BlacklistEnforcementService: ObservableObject {
    static let shared = BlacklistEnforcementService()
    
    @Published var isMonitoring = false
    private var monitorTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastKnownPermissions: Set<String> = []
    
    private init() {}
    
    // MARK: - Monitoring Control
    
    func startMonitoring(interval: TimeInterval = 5.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Initial scan
        scanAndEnforceBlacklist()
        
        // Periodic monitoring
        monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.scanAndEnforceBlacklist()
        }
        
        print("✅ Blacklist enforcement monitoring started")
    }
    
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
        print("🛑 Blacklist enforcement monitoring stopped")
    }
    
    // MARK: - Enforcement Logic
    
    private func scanAndEnforceBlacklist() {
        let blacklist = BlacklistService.shared.blacklistedEntries
        
        guard !blacklist.isEmpty else { return }
        
        // Check both user and system databases
        checkUserDatabase(blacklist: blacklist)
        checkSystemDatabase(blacklist: blacklist)
    }
    
    private func checkUserDatabase(blacklist: [BlacklistEntry]) {
        let userTCCPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
            .path
        
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(userTCCPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return
        }
        
        defer { sqlite3_close(db) }
        
        for entry in blacklist {
            if checkPermissionExists(db: db, service: entry.service, client: entry.client) {
                // Permission found in database - it's been re-added!
                handleBlacklistViolation(entry: entry, isSystemDB: false)
            }
        }
    }
    
    private func checkSystemDatabase(blacklist: [BlacklistEntry]) {
        let systemTCCPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(systemTCCPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return
        }
        
        defer { sqlite3_close(db) }
        
        for entry in blacklist {
            if checkPermissionExists(db: db, service: entry.service, client: entry.client) {
                // Permission found in database - it's been re-added!
                handleBlacklistViolation(entry: entry, isSystemDB: true)
            }
        }
    }
    
    private func checkPermissionExists(db: OpaquePointer?, service: String, client: String) -> Bool {
        let query = "SELECT COUNT(*) FROM access WHERE service = ? AND client = ? AND auth_value = 2"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, service, -1, nil)
        sqlite3_bind_text(statement, 2, client, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let count = sqlite3_column_int(statement, 0)
            return count > 0
        }
        
        return false
    }
    
    private func handleBlacklistViolation(entry: BlacklistEntry, isSystemDB: Bool) {
        print("⚠️ Blacklist violation detected: \(entry.client) attempting to regain \(entry.service)")
        
        // Log the attempt
        BlacklistService.shared.logRevocationAttempt(
            service: entry.service,
            client: entry.client,
            bundleID: entry.bundleID,
            blocked: true
        )
        
        // Re-revoke the permission
        if isSystemDB {
            SystemService.shared.deletePermission(service: entry.service, client: entry.client) { success, message in
                if success {
                    print("✅ Automatically re-revoked system permission: \(entry.client)")
                    self.notifyUser(entry: entry)
                } else {
                    print("❌ Failed to re-revoke system permission: \(message)")
                }
            }
        } else {
            UserService.shared.deletePermission(service: entry.service, client: entry.client) { success, message in
                if success {
                    print("✅ Automatically re-revoked user permission: \(entry.client)")
                    self.notifyUser(entry: entry)
                } else {
                    print("❌ Failed to re-revoke user permission: \(message)")
                }
            }
        }
    }
    
    private func notifyUser(entry: BlacklistEntry) {
        // Send notification to user about blocked attempt
        NotificationCenter.default.post(
            name: NSNotification.Name("BlacklistViolationDetected"),
            object: nil,
            userInfo: [
                "service": entry.service,
                "client": entry.client,
                "bundleID": entry.bundleID ?? "Unknown"
            ]
        )
    }
}
