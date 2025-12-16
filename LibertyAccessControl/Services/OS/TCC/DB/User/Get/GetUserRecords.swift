//
//  GetUserRecords.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

// MARK: - User TCC Database Query Functions
extension UserService {
    
    /// Query entries from the user TCC database using the real home directory path
    func queryEntries() -> [Any] {
        let homeDir = getRealHomeDirectory()
        let userTCCPath = "\(homeDir)/Library/Application Support/com.apple.TCC/TCC.db"
        
        print("Attempting to access: \(userTCCPath)")
        
        var db: OpaquePointer?
        let openResult = sqlite3_open_v2(userTCCPath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOFOLLOW, nil)
        
        guard openResult == SQLITE_OK, db != nil else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
            print("Failed to open user TCC database: \(errorMsg)")
            if db != nil {
                sqlite3_close(db)
            }
            return []
        }
        
        defer {
            sqlite3_close(db)
        }
        
        sqlite3_busy_timeout(db, 5000)
        
        let entries = executeQueryAndParseEntries(db: db)
        return entries
    }
    
    // MARK: - Private Helper Methods
    
    /// Get the real home directory, bypassing sandboxing
    private func getRealHomeDirectory() -> String {
        return ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }
    
    /// Execute the SQL query and parse results into UserEntry objects
    private func executeQueryAndParseEntries(db: OpaquePointer?) -> [UserEntry] {
        let query = """
        SELECT service, client, client_type, auth_value, auth_reason, auth_version,
               csreq, policy_id, indirect_object_identifier_type, indirect_object_identifier,
               indirect_object_code_identity, flags, last_modified, pid, pid_version,
               boot_uuid, last_reminded
        FROM access
        ORDER BY last_modified DESC
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare query")
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        var entries: [UserEntry] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let entry = parseRowIntoEntry(statement: statement) {
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    /// Parse a single row from the query result into a UserEntry
    private func parseRowIntoEntry(statement: OpaquePointer?) -> UserEntry? {
        guard let statement = statement else { return nil }
        
        let service = String(cString: sqlite3_column_text(statement, 0))
        let client = String(cString: sqlite3_column_text(statement, 1))
        let client_type = Int(sqlite3_column_int(statement, 2))
        let auth_value = Int(sqlite3_column_int(statement, 3))
        let auth_reason = Int(sqlite3_column_int(statement, 4))
        let auth_version = Int(sqlite3_column_int(statement, 5))
        
        let csreq = extractBlobData(from: statement, column: 6)
        let policy_id = extractOptionalInt(from: statement, column: 7)
        let indirect_object_identifier_type = extractOptionalInt(from: statement, column: 8)
        let indirect_object_identifier = String(cString: sqlite3_column_text(statement, 9))
        let indirect_object_code_identity = extractBlobData(from: statement, column: 10)
        let flags = extractOptionalInt(from: statement, column: 11)
        let last_modified = extractOptionalDate(from: statement, column: 12)
        let pid = extractOptionalInt(from: statement, column: 13)
        let pid_version = extractOptionalInt(from: statement, column: 14)
        let boot_uuid = String(cString: sqlite3_column_text(statement, 15))
        let last_reminded = extractOptionalDate(from: statement, column: 16)
        
        return UserEntry(
            service: service,
            client: client,
            client_type: client_type,
            auth_value: auth_value,
            auth_reason: auth_reason,
            auth_version: auth_version,
            csreq: csreq,
            policy_id: policy_id,
            indirect_object_identifier_type: indirect_object_identifier_type,
            indirect_object_identifier: indirect_object_identifier,
            indirect_object_code_identity: indirect_object_code_identity,
            flags: flags,
            last_modified: last_modified,
            pid: pid,
            pid_version: pid_version,
            boot_uuid: boot_uuid,
            last_reminded: last_reminded
        )
    }
    
    /// Extract blob data from a column
    private func extractBlobData(from statement: OpaquePointer?, column: Int32) -> Data? {
        guard let blob = sqlite3_column_blob(statement, column) else { return nil }
        let size = Int(sqlite3_column_bytes(statement, column))
        return Data(bytes: blob, count: size)
    }
    
    /// Extract optional integer from a column
    private func extractOptionalInt(from statement: OpaquePointer?, column: Int32) -> Int? {
        return sqlite3_column_type(statement, column) != SQLITE_NULL ? Int(sqlite3_column_int(statement, column)) : nil
    }
    
    /// Extract optional date from a column (stored as Unix timestamp)
    private func extractOptionalDate(from statement: OpaquePointer?, column: Int32) -> Date? {
        let timestamp = sqlite3_column_int64(statement, column)
        return timestamp > 0 ? Date(timeIntervalSince1970: TimeInterval(timestamp)) : nil
    }
}
