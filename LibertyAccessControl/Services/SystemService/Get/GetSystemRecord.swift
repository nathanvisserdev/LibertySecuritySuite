//
//  GetSystemRecord.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation
import SQLite3

// MARK: - System TCC Database Specific Query Functions
extension SystemService {
    func queryEntry(service: String, client: String) -> SystemEntry? {
        let systemTCCPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        var db: OpaquePointer?
        let openResult = sqlite3_open_v2(systemTCCPath, &db, SQLITE_OPEN_READONLY, nil)
        guard openResult == SQLITE_OK, db != nil else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
            print("Failed to open system TCC database: \(errorMsg)")
            if db != nil {
                sqlite3_close(db)
            }
            return nil
        }
        defer {
            sqlite3_close(db)
        }
        
        let entry = executeSpecificQueryAndParseEntry(db: db, service: service, client: client)
        return entry
    }
    
    private func executeSpecificQueryAndParseEntry(db: OpaquePointer?, service: String, client: String) -> SystemEntry? {
        let query = """
        SELECT service, client, client_type, auth_value, auth_reason, auth_version,
               csreq, policy_id, indirect_object_identifier_type, indirect_object_identifier,
               indirect_object_code_identity, flags, last_modified, pid, pid_version,
               boot_uuid, last_reminded
        FROM access
        WHERE service = ? AND client = ?
        LIMIT 1
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Unknown error"
            print("Failed to prepare statement: \(errorMsg)")
            return nil
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        // Bind parameters
        sqlite3_bind_text(statement, 1, (service as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (client as NSString).utf8String, -1, nil)
        
        // Execute query
        if sqlite3_step(statement) == SQLITE_ROW {
            return parseEntry(from: statement)
        }
        
        return nil
    }
    
    private func parseEntry(from statement: OpaquePointer?) -> SystemEntry? {
        guard let statement = statement else { return nil }
        
        let service = String(cString: sqlite3_column_text(statement, 0))
        let client = String(cString: sqlite3_column_text(statement, 1))
        let client_type = Int(sqlite3_column_int(statement, 2))
        let auth_value = Int(sqlite3_column_int(statement, 3))
        let auth_reason = Int(sqlite3_column_int(statement, 4))
        let auth_version = Int(sqlite3_column_int(statement, 5))
        
        // csreq (blob)
        var csreq: Data?
        if let csreqPtr = sqlite3_column_blob(statement, 6) {
            let csreqSize = Int(sqlite3_column_bytes(statement, 6))
            csreq = Data(bytes: csreqPtr, count: csreqSize)
        }
        
        // policy_id
        let policy_id: Int? = sqlite3_column_type(statement, 7) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 7)) : nil
        
        // indirect_object_identifier_type
        let indirect_object_identifier_type: Int? = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil
        
        // indirect_object_identifier
        let indirect_object_identifier = String(cString: sqlite3_column_text(statement, 9))
        
        // indirect_object_code_identity (blob)
        var indirect_object_code_identity: Data?
        if let indirectPtr = sqlite3_column_blob(statement, 10) {
            let indirectSize = Int(sqlite3_column_bytes(statement, 10))
            indirect_object_code_identity = Data(bytes: indirectPtr, count: indirectSize)
        }
        
        // flags
        let flags: Int? = sqlite3_column_type(statement, 11) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 11)) : nil
        
        // last_modified (timestamp)
        var last_modified: Date?
        if sqlite3_column_type(statement, 12) != SQLITE_NULL {
            let timestamp = sqlite3_column_int64(statement, 12)
            last_modified = Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        
        // pid
        let pid: Int? = sqlite3_column_type(statement, 13) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 13)) : nil
        
        // pid_version
        let pid_version: Int? = sqlite3_column_type(statement, 14) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 14)) : nil
        
        // boot_uuid
        let boot_uuid = String(cString: sqlite3_column_text(statement, 15))
        
        // last_reminded (timestamp)
        var last_reminded: Date?
        if sqlite3_column_type(statement, 16) != SQLITE_NULL {
            let timestamp = sqlite3_column_int64(statement, 16)
            last_reminded = Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        
        return SystemEntry(
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
}
