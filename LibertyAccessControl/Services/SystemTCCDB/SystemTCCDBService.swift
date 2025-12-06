//
//  SystemTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

let systemDBPath = "/Library/Application Support/com.apple.TCC/TCC.db"

class SystemTCCDBService {
    
    func openDatabase(readOnly: Bool = true) -> OpaquePointer? {
        var db: OpaquePointer?
        let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE
        let openResult = sqlite3_open_v2(systemDBPath, &db, flags, nil)
        
        guard openResult == SQLITE_OK else {
            if db != nil {
                sqlite3_close(db)
            }
            return nil
        }
        
        return db
    }
}
