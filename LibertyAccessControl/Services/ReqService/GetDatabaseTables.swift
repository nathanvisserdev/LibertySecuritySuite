//
//  GetDatabaseTables.swift
//  LibertyAccessControl
//
//  Created on 2025-12-10.
//

import Foundation
import SQLite3

// MARK: - Database Schema Models

struct TableSchema: Identifiable {
    let id = UUID()
    let name: String
    var columns: [String] = []
    var rows: [[String: String]] = [] // Array of dictionaries (column_name: value)
}

// MARK: - Get All Tables from a Database

class DatabaseTablesService {
    /// Query all table names and their columns from a TCC database
    func getDatabaseTables(databasePath: String, completion: @escaping ([TableSchema], String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var db: OpaquePointer?
            var tables: [TableSchema] = []
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
            let tableQuery = """
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            ORDER BY name
            """
            
            var statement: OpaquePointer?
            
            guard sqlite3_prepare_v2(db, tableQuery, -1, &statement, nil) == SQLITE_OK else {
                errorMessage = "Failed to prepare query for tables"
                DispatchQueue.main.async {
                    completion([], errorMessage)
                }
                return
            }
            
            var tableNames: [String] = []
            
            // Execute query and collect table names
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let tableName = String(cString: cString)
                    tableNames.append(tableName)
                }
            }
            
            sqlite3_finalize(statement)
            
            // For each table, get its columns and data
            for tableName in tableNames {
                var table = TableSchema(name: tableName)
                
                let columnQuery = "PRAGMA table_info(\(tableName))"
                var columnStatement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, columnQuery, -1, &columnStatement, nil) == SQLITE_OK {
                    while sqlite3_step(columnStatement) == SQLITE_ROW {
                        // Column name is at index 1 in PRAGMA table_info result
                        if let cString = sqlite3_column_text(columnStatement, 1) {
                            let columnName = String(cString: cString)
                            table.columns.append(columnName)
                        }
                    }
                    sqlite3_finalize(columnStatement)
                }
                
                // Query all rows from this table
                if !table.columns.isEmpty {
                    let dataQuery = "SELECT * FROM \(tableName)"
                    var dataStatement: OpaquePointer?
                    
                    if sqlite3_prepare_v2(db, dataQuery, -1, &dataStatement, nil) == SQLITE_OK {
                        while sqlite3_step(dataStatement) == SQLITE_ROW {
                            var row: [String: String] = [:]
                            
                            // Read each column value
                            for (index, columnName) in table.columns.enumerated() {
                                let columnType = sqlite3_column_type(dataStatement, Int32(index))
                                
                                let value: String
                                switch columnType {
                                case SQLITE_INTEGER:
                                    value = String(sqlite3_column_int64(dataStatement, Int32(index)))
                                case SQLITE_FLOAT:
                                    value = String(sqlite3_column_double(dataStatement, Int32(index)))
                                case SQLITE_TEXT:
                                    if let cString = sqlite3_column_text(dataStatement, Int32(index)) {
                                        value = String(cString: cString)
                                    } else {
                                        value = ""
                                    }
                                case SQLITE_BLOB:
                                    if let blob = sqlite3_column_blob(dataStatement, Int32(index)) {
                                        let size = sqlite3_column_bytes(dataStatement, Int32(index))
                                        let data = Data(bytes: blob, count: Int(size))
                                        value = "<BLOB: \(size) bytes> \(data.prefix(20).map { String(format: "%02x", $0) }.joined())"
                                    } else {
                                        value = "<BLOB: empty>"
                                    }
                                case SQLITE_NULL:
                                    value = "NULL"
                                default:
                                    value = "<unknown type>"
                                }
                                
                                row[columnName] = value
                            }
                            
                            table.rows.append(row)
                        }
                        sqlite3_finalize(dataStatement)
                    }
                }
                
                tables.append(table)
            }
            
            DispatchQueue.main.async {
                completion(tables, nil)
            }
        }
    }
}
