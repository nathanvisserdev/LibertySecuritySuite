//
//  TCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

protocol TCCDatabaseService {
    func queryEntries() -> [Any]
    func updatePermission(service: String, client: String, authValue: Int, completion: @escaping (Bool, String) -> Void)
    func deletePermission(service: String, client: String, completion: @escaping (Bool, String) -> Void)
}

class BaseTCCDatabaseService {
    let dbPath: String
    
    init(dbPath: String) {
        self.dbPath = dbPath
    }
    
    func stopTCCD() {
        // Kill tccd with sudo to ensure it dies and can't write cache back
        let script = "do shell script \"killall -9 tccd\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("💀 tccd killed with admin privileges (exit code: \(process.terminationStatus))")
            Thread.sleep(forTimeInterval: 1.0)
        } catch {
            print("❌ Failed to kill tccd: \(error)")
        }
    }
    
    func restartTCCD() {
        // tccd will auto-restart via launchd, just wait for it
        print("⏳ Waiting for tccd to auto-restart...")
        Thread.sleep(forTimeInterval: 2.0)
        print("✅ tccd should be restarted now")
    }
    
    func openDatabase(readOnly: Bool = true) -> OpaquePointer? {
        var db: OpaquePointer?
        let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE
        let openResult = sqlite3_open_v2(dbPath, &db, flags, nil)
        
        guard openResult == SQLITE_OK else {
            if db != nil {
                sqlite3_close(db)
            }
            return nil
        }
        
        return db
    }
}
