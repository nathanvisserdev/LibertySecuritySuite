//
//  ReviseUserRecords.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

// MARK: - User TCC Database Update Functions
extension UserTCCDatabaseService {
    
    /// Update a permission in the user TCC database
    func updatePermission(service: String, client: String, authValue: Int, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            print("🔍 UPDATE REQUEST: service='\(service)', client='\(client)', authValue=\(authValue)")
            
            guard let db = self.openDatabase(readOnly: false) else {
                DispatchQueue.main.async {
                    completion(false, "Failed to open user TCC database")
                }
                return
            }
            
            defer { sqlite3_close(db) }
            
            // Execute update within a transaction
            let success = self.executeUpdate(
                db: db,
                service: service,
                client: client,
                authValue: authValue
            )
            
            if success {
                // Verify the update
                self.verifyUpdate(service: service, client: client, expectedValue: authValue)
                
                DispatchQueue.main.async {
                    completion(true, "Successfully updated user permission to \(authValue == 2 ? "ALLOWED" : "DENIED")")
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Failed to update permission")
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Execute an UPDATE transaction
    private func executeUpdate(db: OpaquePointer?, service: String, client: String, authValue: Int) -> Bool {
        // Begin transaction
        guard beginTransaction(db: db) else { return false }
        
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
            print("❌ Failed to prepare statement: \(errorMsg)")
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
            print("📝 UPDATE RESULT: \(changes) row(s) changed")
            
            // Commit transaction
            commitTransaction(db: db)
            return changes > 0
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to update: \(errorMsg)")
            return false
        }
    }
    
    /// Begin a database transaction
    private func beginTransaction(db: OpaquePointer?) -> Bool {
        var beginStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "BEGIN TRANSACTION", -1, &beginStmt, nil) == SQLITE_OK else {
            return false
        }
        sqlite3_step(beginStmt)
        sqlite3_finalize(beginStmt)
        return true
    }
    
    /// Commit a database transaction
    private func commitTransaction(db: OpaquePointer?) {
        var commitStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "COMMIT", -1, &commitStmt, nil) == SQLITE_OK {
            sqlite3_step(commitStmt)
            sqlite3_finalize(commitStmt)
            print("💾 Transaction committed")
        }
    }
    
    /// Verify that an update was successful
    private func verifyUpdate(service: String, client: String, expectedValue: Int) {
        Thread.sleep(forTimeInterval: 0.2)
        
        guard let verifyDb = openDatabase() else { return }
        defer { sqlite3_close(verifyDb) }
        
        let verifyQuery = "SELECT auth_value FROM access WHERE service = ? AND client = ?"
        var verifyStmt: OpaquePointer?
        
        if sqlite3_prepare_v2(verifyDb, verifyQuery, -1, &verifyStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(verifyStmt, 1, service, -1, nil)
            sqlite3_bind_text(verifyStmt, 2, client, -1, nil)
            
            if sqlite3_step(verifyStmt) == SQLITE_ROW {
                let verifiedValue = Int(sqlite3_column_int(verifyStmt, 0))
                print("🔍 VERIFIED: auth_value is now \(verifiedValue)")
            }
            sqlite3_finalize(verifyStmt)
        }
    }
}
