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
