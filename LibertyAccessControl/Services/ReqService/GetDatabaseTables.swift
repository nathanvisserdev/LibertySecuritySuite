//
//  GetDatabaseTables.swift
//  LibertyAccessControl
//
//  Created on 2025-12-10.
//

import Foundation
import SQLite3

// MARK: - Get All Tables from a Database

class DatabaseTablesService {
    /// Query all table names from a TCC database
    func getDatabaseTables(databasePath: String, completion: @escaping ([String], String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var db: OpaquePointer?
            var tables: [String] = []
            var errorMessage: String?
            
            let openResult = sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READONLY, nil)
            
            guard openResult == SQLITE_OK, db != nil else {
                let error = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
                errorMessage = "Failed to open database at \(databasePath): \(error)"
                if db != nil {
                    sqlite3_close(db)
                }
                DispatchQueue.main.async {
                    completion([], errorMessage)
                }
                return
            }
            
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            // Query to get all table names
            let query = """
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            ORDER BY name
            """
            
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
                errorMessage = "Failed to prepare query for tables"
                DispatchQueue.main.async {
                    completion([], errorMessage)
                }
                return
            }
            
            defer { sqlite3_finalize(statement) }
            
            // Execute query and collect table names
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let tableName = String(cString: cString)
                    tables.append(tableName)
                }
            }
            
            DispatchQueue.main.async {
                completion(tables, nil)
            }
        }
    }
}
