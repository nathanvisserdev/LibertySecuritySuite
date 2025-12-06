//
//  ReviseSystemRecords.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

// MARK: - System TCC Database Update Functions
extension SystemTCCDBService {
    
    /// Update a permission in the system TCC database
    func updatePermission(service: String, client: String, authValue: Int, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let db = self.openDatabase(readOnly: false) else {
                DispatchQueue.main.async {
                    completion(false, "Failed to open system TCC database. Requires root privileges.")
                }
                return
            }
            
            defer { sqlite3_close(db) }
            
            let success = self.executeUpdate(db: db, service: service, client: client, authValue: authValue)
            
            if success {
                DispatchQueue.main.async {
                    completion(true, "Successfully updated system permission to \(authValue == 2 ? "ALLOWED" : "DENIED")")
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Failed to update permission")
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Execute an UPDATE query
    private func executeUpdate(db: OpaquePointer?, service: String, client: String, authValue: Int) -> Bool {
        let updateQuery = """
        UPDATE access 
        SET auth_value = ?, 
            auth_reason = 1, 
            last_modified = ?
        WHERE service = ? AND client = ?
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare update statement: \(errorMsg)")
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        
        let currentTime = Int64(Date().timeIntervalSince1970)
        
        sqlite3_bind_int(statement, 1, Int32(authValue))
        sqlite3_bind_int64(statement, 2, currentTime)
        sqlite3_bind_text(statement, 3, service, -1, nil)
        sqlite3_bind_text(statement, 4, client, -1, nil)
        
        let stepResult = sqlite3_step(statement)
        
        if stepResult == SQLITE_DONE {
            let changes = sqlite3_changes(db)
            print("✅ UPDATE RESULT: \(changes) row(s) updated")
            return changes > 0
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to update: \(errorMsg)")
            return false
        }
    }
}
