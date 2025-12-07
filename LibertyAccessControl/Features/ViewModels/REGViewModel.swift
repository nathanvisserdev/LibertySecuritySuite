//
//  REGViewModel.swift (System TCC Registry Database)
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import SQLite3

struct REGEntry: Identifiable {
    let id = UUID()
    let abs_path: String
    let first_seen: Date
    let last_seen: Date
    let trusted: Int
    
    var isTrusted: Bool {
        trusted != 0
    }
}

class REGViewModel: ObservableObject {
    @Published var statusMessage: String = "System TCC Registry Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [REGEntry] = []
    @Published var isLoading: Bool = false
    
    func loadREGData() {
        isLoading = true
        statusMessage = "Loading system TCC registry database..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let results = self?.queryREGDatabase() ?? []
            
            DispatchQueue.main.async {
                self?.entries = results
                self?.isLoading = false
                if results.isEmpty {
                    self?.statusMessage = "No registry entries found"
                } else {
                    self?.statusMessage = "Loaded \(results.count) registry entries"
                }
            }
        }
    }
    
    private func queryREGDatabase() -> [REGEntry] {
        let regDBPath = "/Library/Application Support/com.apple.TCC/REG.db"
        
        var db: OpaquePointer?
        var entries: [REGEntry] = []
        
        let openResult = sqlite3_open_v2(regDBPath, &db, SQLITE_OPEN_READONLY, nil)
        
        guard openResult == SQLITE_OK, db != nil else {
            let errorMsg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database"
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to open registry database at \(regDBPath): \(errorMsg). Make sure the app has Full Disk Access permission."
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
        
        // Query the registry table
        let query = """
        SELECT abs_path, first_seen, last_seen, trusted
        FROM registry 
        ORDER BY last_seen DESC
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
            let abs_path = String(cString: sqlite3_column_text(statement, 0))
            let first_seen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let last_seen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let trusted = Int(sqlite3_column_int(statement, 3))
            
            let entry = REGEntry(
                abs_path: abs_path,
                first_seen: first_seen,
                last_seen: last_seen,
                trusted: trusted
            )
            entries.append(entry)
        }
        
        return entries
    }
}
