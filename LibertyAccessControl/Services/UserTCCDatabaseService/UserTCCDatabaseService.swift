//
//  UserTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

class UserTCCDatabaseService: BaseTCCDatabaseService, TCCDatabaseService {
    
    init() {
        super.init(dbPath: "\(NSHomeDirectory())/Library/Application Support/com.apple.TCC/TCC.db")
    }
    
    private func stopTCCD() {
        // Kill tccd without admin privileges for user database
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["-9", "tccd"]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("💀 tccd killed (user-level, exit code: \(process.terminationStatus))")
            Thread.sleep(forTimeInterval: 1.0)
        } catch {
            print("❌ Failed to kill tccd: \(error)")
        }
    }
    
    func updatePermission(service: String, client: String, authValue: Int, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            print("🔍 UPDATE REQUEST: service='\(service)', client='\(client)', authValue=\(authValue)")
            
            // User database doesn't require stopping tccd - just open and modify directly
            guard let db = self.openDatabase(readOnly: false) else {
                DispatchQueue.main.async {
                    completion(false, "Failed to open user TCC database")
                }
                return
            }
            
            // Begin explicit transaction
            var beginStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, "BEGIN TRANSACTION", -1, &beginStmt, nil) == SQLITE_OK else {
                sqlite3_close(db)
                DispatchQueue.main.async {
                    completion(false, "Failed to begin transaction")
                }
                return
            }
            sqlite3_step(beginStmt)
            sqlite3_finalize(beginStmt)
            
            // Update the auth_value and last_modified for the existing entry
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
                sqlite3_close(db)
                DispatchQueue.main.async {
                    completion(false, "Failed to prepare statement: \(errorMsg)")
                }
                return
            }
            
            let currentTime = Int64(Date().timeIntervalSince1970)
            
            sqlite3_bind_int(statement, 1, Int32(authValue))
            sqlite3_bind_int64(statement, 2, currentTime)
            sqlite3_bind_text(statement, 3, service, -1, nil)
            sqlite3_bind_text(statement, 4, client, -1, nil)
            
            let stepResult = sqlite3_step(statement)
            
            if stepResult == SQLITE_DONE {
                let changes = sqlite3_changes(db)
                print("📝 UPDATE RESULT: \(changes) row(s) changed")
                
                // Finalize the statement
                sqlite3_finalize(statement)
                statement = nil
                
                // Commit the transaction
                var commitStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, "COMMIT", -1, &commitStmt, nil) == SQLITE_OK {
                    sqlite3_step(commitStmt)
                    sqlite3_finalize(commitStmt)
                    print("💾 Transaction committed")
                }
                
                // Close the database to ensure changes are flushed
                sqlite3_close(db)
                
                if changes > 0 {
                    // Verify the update
                    Thread.sleep(forTimeInterval: 0.2)
                    if let verifyDb = self.openDatabase() {
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
                        sqlite3_close(verifyDb)
                    }
                    
                    DispatchQueue.main.async {
                        completion(true, "Successfully updated user permission to \(authValue == 2 ? "ALLOWED" : "DENIED")")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "No matching entry found to update (service: \(service), client: \(client))")
                    }
                }
                return
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                sqlite3_finalize(statement)
                statement = nil
                sqlite3_close(db)
                DispatchQueue.main.async {
                    completion(false, "Failed to update: \(errorMsg)")
                }
                return
            }
        }
    }
    
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
            
            let deleteQuery = "DELETE FROM access WHERE service = ? AND client = ?"
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                DispatchQueue.main.async {
                    completion(false, "Failed to prepare statement: \(errorMsg)")
                }
                return
            }
            
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_text(statement, 1, service, -1, nil)
            sqlite3_bind_text(statement, 2, client, -1, nil)
            
            let stepResult = sqlite3_step(statement)
            
            if stepResult == SQLITE_DONE {
                DispatchQueue.main.async {
                    completion(true, "Successfully deleted user permission")
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                DispatchQueue.main.async {
                    completion(false, "Failed to delete: \(errorMsg)")
                }
            }
        }
    }
}
