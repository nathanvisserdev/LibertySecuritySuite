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
    
    func queryEntries() -> [Any] {
        guard let db = openDatabase() else {
            return []
        }
        
        defer { sqlite3_close(db) }
        
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
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        var entries: [TCCSystemEntry] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let service = String(cString: sqlite3_column_text(statement, 0))
            let client = String(cString: sqlite3_column_text(statement, 1))
            let client_type = Int(sqlite3_column_int(statement, 2))
            let auth_value = Int(sqlite3_column_int(statement, 3))
            let auth_reason = Int(sqlite3_column_int(statement, 4))
            let auth_version = Int(sqlite3_column_int(statement, 5))
            
            var csreq: Data?
            if let blob = sqlite3_column_blob(statement, 6) {
                let size = Int(sqlite3_column_bytes(statement, 6))
                csreq = Data(bytes: blob, count: size)
            }
            
            let policy_id = sqlite3_column_type(statement, 7) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 7)) : nil
            let indirect_object_identifier_type = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil
            let indirect_object_identifier = String(cString: sqlite3_column_text(statement, 9))
            
            var indirect_object_code_identity: Data?
            if let blob = sqlite3_column_blob(statement, 10) {
                let size = Int(sqlite3_column_bytes(statement, 10))
                indirect_object_code_identity = Data(bytes: blob, count: size)
            }
            
            let flags = sqlite3_column_type(statement, 11) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 11)) : nil
            let last_modified_int = sqlite3_column_int64(statement, 12)
            let last_modified = last_modified_int > 0 ? Date(timeIntervalSince1970: TimeInterval(last_modified_int)) : nil
            let pid = sqlite3_column_type(statement, 13) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 13)) : nil
            let pid_version = sqlite3_column_type(statement, 14) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 14)) : nil
            let boot_uuid = String(cString: sqlite3_column_text(statement, 15))
            let last_reminded_int = sqlite3_column_int64(statement, 16)
            let last_reminded = last_reminded_int > 0 ? Date(timeIntervalSince1970: TimeInterval(last_reminded_int)) : nil
            
            let entry = TCCSystemEntry(
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
            entries.append(entry)
        }
        
        return entries
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
            
            let updateQuery = """
            INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags, last_modified)
            VALUES (?, ?, 0, ?, 1, 1, 0, ?)
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
            
            sqlite3_bind_text(statement, 1, service, -1, nil)
            sqlite3_bind_text(statement, 2, client, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(authValue))
            sqlite3_bind_int64(statement, 4, currentTime)
            
            let stepResult = sqlite3_step(statement)
            
            if stepResult == SQLITE_DONE {
                self.restartTCCD()
                DispatchQueue.main.async {
                    completion(true, "Successfully updated system permission")
                }
            } else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                DispatchQueue.main.async {
                    completion(false, "Failed to update: \(errorMsg)")
                }
            }
        }
    }
    
    func deletePermission(service: String, client: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let db = self.openDatabase(readOnly: false) else {
                DispatchQueue.main.async {
                    completion(false, "Failed to open system TCC database. Requires root privileges.")
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
                self.restartTCCD()
                DispatchQueue.main.async {
                    completion(true, "Successfully deleted system permission")
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
