//
//  TCCViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import SQLite3

struct TCCEntry: Identifiable {
    let id = UUID()
    let client: String          // Bundle ID or path
    let service: String         // kTCCServiceCamera, etc.
    let authValue: Int          // 0=denied, 1=unknown, 2=allowed, 3=limited
    let clientType: Int         // 0=bundleID, 1=path
    let lastModified: Date?
    
    var serviceName: String {
        service.replacingOccurrences(of: "kTCCService", with: "")
    }
    
    var statusText: String {
        switch authValue {
        case 0: return "Denied"
        case 2: return "Allowed"
        case 3: return "Limited"
        default: return "Unknown"
        }
    }
    
    var statusColor: String {
        switch authValue {
        case 0: return "red"
        case 2: return "green"
        case 3: return "orange"
        default: return "gray"
        }
    }
}

class TCCViewModel: ObservableObject {
    @Published var statusMessage: String = "TCC Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [TCCEntry] = []
    @Published var isLoading: Bool = false
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Loading TCC database..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let results = self?.queryTCCDatabase() ?? []
            
            DispatchQueue.main.async {
                self?.entries = results
                self?.isLoading = false
                if results.isEmpty {
                    self?.statusMessage = "No TCC entries found"
                    self?.errorMessage = "Make sure the app has Full Disk Access permission"
                } else {
                    self?.statusMessage = "Loaded \(results.count) TCC entries"
                }
            }
        }
    }
    
    private func queryTCCDatabase() -> [TCCEntry] {
        let tccPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        var db: OpaquePointer?
        var entries: [TCCEntry] = []
        
        // Open database
        guard sqlite3_open_v2(tccPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to open TCC database"
            }
            return []
        }
        
        defer { sqlite3_close(db) }
        
        // Query the access table
        let query = """
        SELECT client, service, auth_value, client_type, last_modified 
        FROM access 
        ORDER BY last_modified DESC
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to prepare query"
            }
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Execute query and collect results
        while sqlite3_step(statement) == SQLITE_ROW {
            let client = String(cString: sqlite3_column_text(statement, 0))
            let service = String(cString: sqlite3_column_text(statement, 1))
            let authValue = Int(sqlite3_column_int(statement, 2))
            let clientType = Int(sqlite3_column_int(statement, 3))
            let lastModified = sqlite3_column_int64(statement, 4)
            
            let entry = TCCEntry(
                client: client,
                service: service,
                authValue: authValue,
                clientType: clientType,
                lastModified: lastModified > 0 ? Date(timeIntervalSince1970: TimeInterval(lastModified)) : nil
            )
            entries.append(entry)
        }
        
        return entries
    }
}
