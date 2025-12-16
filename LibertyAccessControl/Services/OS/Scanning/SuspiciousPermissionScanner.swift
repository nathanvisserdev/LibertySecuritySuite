//
//  SuspiciousPermissionScanner.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import SQLite3

struct SuspiciousApp {
    let bundleID: String
    let client: String
    let unauthorizedServices: Set<String>
    let allGrantedServices: Set<String>
    let isKnownApp: Bool
    let detectedAt: Date
}

class SuspiciousPermissionScanner {
    private let whitelist: KnownAppsWhitelist
    private let blacklistService: BlacklistService
    
    init(whitelist: KnownAppsWhitelist = .shared, blacklistService: BlacklistService = .shared) {
        self.whitelist = whitelist
        self.blacklistService = blacklistService
    }
    
    // MARK: - Scan Methods
    
    func scanAllDatabases(completion: @escaping ([SuspiciousApp]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var allSuspicious: [SuspiciousApp] = []
            
            // Scan user database
            allSuspicious.append(contentsOf: self.scanUserDatabase())
            
            // Scan system database
            allSuspicious.append(contentsOf: self.scanSystemDatabase())
            
            DispatchQueue.main.async {
                completion(allSuspicious)
            }
        }
    }
    
    private func scanUserDatabase() -> [SuspiciousApp] {
        let userTCCPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
            .path
        
        return scanDatabase(at: userTCCPath)
    }
    
    private func scanSystemDatabase() -> [SuspiciousApp] {
        let systemTCCPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        return scanDatabase(at: systemTCCPath)
    }
    
    private func scanDatabase(at path: String) -> [SuspiciousApp] {
        var db: OpaquePointer?
        var suspiciousApps: [SuspiciousApp] = []
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return []
        }
        
        defer { sqlite3_close(db) }
        
        // Group permissions by client
        let appPermissions = getAppPermissions(db: db)
        
        for (client, services) in appPermissions {
            // Extract bundle ID from client path or csreq
            guard let bundleID = extractBundleID(client: client, db: db) else {
                continue
            }
            
            // Skip already blacklisted apps
            if blacklistService.isBlacklisted(service: services.first ?? "", client: client) {
                continue
            }
            
            let isKnown = whitelist.isKnownApp(bundleID)
            let unauthorized = whitelist.getUnauthorizedPermissions(bundleID: bundleID, grantedServices: services)
            
            // Flag if unknown app OR known app with unauthorized permissions
            if !isKnown || !unauthorized.isEmpty {
                let suspicious = SuspiciousApp(
                    bundleID: bundleID,
                    client: client,
                    unauthorizedServices: unauthorized,
                    allGrantedServices: services,
                    isKnownApp: isKnown,
                    detectedAt: Date()
                )
                suspiciousApps.append(suspicious)
            }
        }
        
        return suspiciousApps
    }
    
    private func getAppPermissions(db: OpaquePointer?) -> [String: Set<String>] {
        var appPermissions: [String: Set<String>] = [:]
        
        let query = "SELECT client, service FROM access WHERE auth_value = 2"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return [:]
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let client = String(cString: sqlite3_column_text(statement, 0))
            let service = String(cString: sqlite3_column_text(statement, 1))
            
            if appPermissions[client] == nil {
                appPermissions[client] = Set<String>()
            }
            appPermissions[client]?.insert(service)
        }
        
        return appPermissions
    }
    
    private func extractBundleID(client: String, db: OpaquePointer?) -> String? {
        // Try to extract from client path (e.g., /Applications/Safari.app -> com.apple.Safari)
        if let bundleIDFromPath = getBundleIDFromPath(client) {
            return bundleIDFromPath
        }
        
        // Try to extract from csreq blob
        if let bundleIDFromCSReq = getBundleIDFromCSReq(client: client, db: db) {
            return bundleIDFromCSReq
        }
        
        // Fallback: use client path as identifier
        return client
    }
    
    private func getBundleIDFromPath(_ path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        
        // Check if it's an app bundle
        if path.hasSuffix(".app") {
            if let bundle = Bundle(url: url) {
                return bundle.bundleIdentifier
            }
        }
        
        return nil
    }
    
    private func getBundleIDFromCSReq(client: String, db: OpaquePointer?) -> String? {
        let query = "SELECT csreq FROM access WHERE client = ? LIMIT 1"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, client, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let blob = sqlite3_column_blob(statement, 0) {
                let size = Int(sqlite3_column_bytes(statement, 0))
                let csreq = Data(bytes: blob, count: size)
                return parseCSReqBundleID(from: csreq)
            }
        }
        
        return nil
    }
    
    private func parseCSReqBundleID(from data: Data) -> String? {
        guard data.count >= 8 else { return nil }
        
        var offset = 8
        
        while offset + 8 < data.count {
            let op = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }.bigEndian
            
            if op == 0x00000002 {
                offset += 4
                let length = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }.bigEndian)
                offset += 4
                
                if offset + length <= data.count {
                    let stringData = data.subdata(in: offset..<(offset + length))
                    if let bundleID = String(data: stringData, encoding: .utf8) {
                        return bundleID
                    }
                }
                break
            }
            offset += 4
        }
        
        return nil
    }
    
    // MARK: - Auto-Blacklist
    
    func autoBlacklistSuspiciousApps(suspiciousApps: [SuspiciousApp], completion: @escaping (Int) -> Void) {
        var blacklistedCount = 0
        
        for app in suspiciousApps {
            let allServicesArray = Array(app.allGrantedServices)
            
            // Add one blacklist entry per service, but include all services in metadata
            for service in app.allGrantedServices {
                blacklistService.addToBlacklist(
                    service: service,
                    client: app.client,
                    bundleID: app.bundleID,
                    teamID: nil,
                    reason: app.isKnownApp 
                        ? "Unauthorized permissions detected: \(app.unauthorizedServices.joined(separator: ", "))"
                        : "Unknown app with granted permissions",
                    allRevokedServices: allServicesArray,
                    wasAutomaticallyBlacklisted: true
                )
                
                blacklistService.logRevocationAttempt(
                    service: service,
                    client: app.client,
                    bundleID: app.bundleID,
                    blocked: false
                )
            }
            
            blacklistedCount += 1
            print("🚫 Auto-blacklisted: \(app.bundleID) - \(app.unauthorizedServices.count) unauthorized permissions")
        }
        
        completion(blacklistedCount)
    }
}
