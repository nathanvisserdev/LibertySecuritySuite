//
//  SystemTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

class SystemTCCDatabaseService: BaseTCCDatabaseService, TCCDatabaseService {
    
    init() {
        super.init(dbPath: "/Library/Application Support/com.apple.TCC/TCC.db")
    }
    
    private func stopTCCD() {
        // Kill tccd with sudo to ensure it dies and can't write cache back
        let script = "do shell script \"killall -9 tccd\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        do {
            try process.run()
            // User clicks OK after entering credentials here
            process.waitUntilExit()
            print("💀 tccd killed with admin privileges (exit code: \(process.terminationStatus))")
            Thread.sleep(forTimeInterval: 1.0)
        } catch {
            print("❌ Failed to kill tccd: \(error)")
        }
    }
    
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
                DispatchQueue.main.async {
                    completion(false, "Failed to prepare statement: \(errorMsg)")
                }
                return
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
                if changes > 0 {
                    self.restartTCCD()
                    DispatchQueue.main.async {
                        completion(true, "Successfully updated system permission to \(authValue == 2 ? "ALLOWED" : "DENIED")")
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "No matching entry found to update")
                    }
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                DispatchQueue.main.async {
                    completion(false, "Failed to update: \(errorMsg)")
                }
            }
        }
    }
}
