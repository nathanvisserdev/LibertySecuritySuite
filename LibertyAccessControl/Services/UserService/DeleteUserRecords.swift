//
//  DeleteUserRecords.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

// MARK: - User TCC Database Delete Functions
extension UserService {
    
    func deletePermission(service: String, client: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let db = self.openDatabase(readOnly: false) else {
                DispatchQueue.main.async {
                    completion(false, "Failed to open user TCC database")
                }
                return
            }
            
            defer { sqlite3_close(db) }
            
            let success = self.executeDelete(db: db, service: service, client: client)
            
            DispatchQueue.main.async {
                if success {
                    completion(true, "Successfully deleted user permission")
                } else {
                    completion(false, "Failed to delete permission")
                }
            }
        }
    }
    
    /// Revoke permission and add to blacklist to prevent re-enabling
    /// Now uses TCCRevocationService for full cache invalidation
    func revokeAndBlacklistPermission(service: String, client: String, bundleID: String?, teamID: String?, reason: String? = nil, completion: @escaping (Bool, String) -> Void) {
        // Delegate to TCCRevocationService for comprehensive revocation with cache handling
        TCCRevocationService.shared.revokeUserPermission(
            service: service,
            client: client,
            bundleID: bundleID,
            teamID: teamID,
            reason: reason,
            completion: completion
        )
    }
    
    private func executeDelete(db: OpaquePointer?, service: String, client: String) -> Bool {
        let deleteQuery = "DELETE FROM access WHERE service = ? AND client = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare delete statement: \(errorMsg)")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, service, -1, nil)
        sqlite3_bind_text(statement, 2, client, -1, nil)
        
        let stepResult = sqlite3_step(statement)
        
        if stepResult == SQLITE_DONE {
            let changes = sqlite3_changes(db)
            print("✅ DELETE RESULT: \(changes) row(s) deleted")
            return changes > 0
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to delete: \(errorMsg)")
            return false
        }
    }
}
