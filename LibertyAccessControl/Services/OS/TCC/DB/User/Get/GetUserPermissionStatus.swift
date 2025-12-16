//
//  GetPermissionStatus.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import SQLite3

extension UserService {
    /// Query TCC authorization status for a specific service and client (app bundle ID)
    func getPermissionStatus(service: String, clientBundleID: String) -> (granted: Bool, found: Bool) {
        guard let db = openDatabase() else {
            return (false, false)
        }
        defer { sqlite3_close(db) }
        
        let query = "SELECT auth_value FROM access WHERE service = ? AND client = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return (false, false)
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (service as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (clientBundleID as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let authValue = Int(sqlite3_column_int(statement, 0))
            // auth_value: 0 = denied, 2 = allowed, 3 = limited (for photos)
            return (authValue == 2 || authValue == 3, true)
        }
        
        return (false, false)
    }
    
    /// Get the raw auth_value for a specific service and client
    func getAuthValue(service: String, clientBundleID: String) -> Int? {
        guard let db = openDatabase() else {
            return nil
        }
        defer { sqlite3_close(db) }
        
        let query = "SELECT auth_value FROM access WHERE service = ? AND client = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (service as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (clientBundleID as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        
        return nil
    }
}
