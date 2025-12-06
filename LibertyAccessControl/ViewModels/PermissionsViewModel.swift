//
//  PermissionsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import Combine
import SQLite3

class PermissionsViewModel: ObservableObject {
    @Published var statusMessage: String = "All Permissions - Ready to query"
    @Published var errorMessage: String?
    @Published var systemEntries: [TCCSystemEntry] = []
    @Published var userEntries: [TCCUserEntry] = []
    @Published var isLoading: Bool = false
    
    private let systemDBService: SystemTCCDatabaseService
    private let userDBService: UserTCCDatabaseService
    
    init(systemDBService: SystemTCCDatabaseService, userDBService: UserTCCDatabaseService) {
        self.systemDBService = systemDBService
        self.userDBService = userDBService
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Loading all permissions..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let systemResults = self.systemDBService.queryEntries().compactMap { $0 as? TCCSystemEntry }
            let userResults = self.userDBService.queryEntries().compactMap { $0 as? TCCUserEntry }
            
            DispatchQueue.main.async {
                self.systemEntries = systemResults
                self.userEntries = userResults
                self.isLoading = false
                self.statusMessage = "Loaded \(systemResults.count) system entries and \(userResults.count) user entries"
            }
        }
    }
    
    func updatePermission(service: String, client: String, authValue: Int, isSystemDB: Bool, completion: @escaping (Bool, String) -> Void) {
        if isSystemDB {
            systemDBService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        } else {
            userDBService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        }
    }
    
    private func querySystemTCCDatabase() -> [TCCSystemEntry] {
        let systemTCCPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        
        var db: OpaquePointer?
        var entries: [TCCSystemEntry] = []
        
        let openResult = sqlite3_open_v2(systemTCCPath, &db, SQLITE_OPEN_READONLY, nil)
        
        guard openResult == SQLITE_OK, db != nil else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to open system TCC database: \(errorMsg)"
            }
            if db != nil {
                sqlite3_close(db)
            }
            return []
        }
        
        defer { 
            if db != nil {
                sqlite3_close(db)
            }
        }
        
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
    
    private func queryUserTCCDatabase() -> [TCCUserEntry] {
        let homeDir = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        let userTCCPath = "\(homeDir)/Library/Application Support/com.apple.TCC/TCC.db"
        
        // Kill the user tccd process to release the database lock
        let killTask = Process()
        killTask.launchPath = "/usr/bin/pkill"
        killTask.arguments = ["-u", NSUserName(), "tccd"]
        try? killTask.run()
        killTask.waitUntilExit()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        var db: OpaquePointer?
        var entries: [TCCUserEntry] = []
        
        let openResult = sqlite3_open_v2(userTCCPath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOFOLLOW, nil)
        
        guard openResult == SQLITE_OK, db != nil else {
            if db != nil {
                sqlite3_close(db)
            }
            return []
        }
        
        defer { 
            if db != nil {
                sqlite3_close(db)
            }
        }
        
        sqlite3_busy_timeout(db, 5000)
        
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
            
            let entry = TCCUserEntry(
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
}
