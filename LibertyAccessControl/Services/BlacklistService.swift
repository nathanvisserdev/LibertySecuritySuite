//
//  BlacklistService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

class BlacklistService: ObservableObject {
    static let shared = BlacklistService()
    
    @Published var blacklistedEntries: [BlacklistEntry] = []
    @Published var revocationAttempts: [RevocationAttempt] = []
    
    private let blacklistKey = "com.libertyaccesscontrol.blacklist"
    private let attemptsKey = "com.libertyaccesscontrol.revocation_attempts"
    
    private init() {
        loadBlacklist()
        loadAttempts()
    }
    
    // MARK: - Blacklist Management
    
    func addToBlacklist(service: String, client: String, bundleID: String?, teamID: String?, reason: String? = nil) {
        let entry = BlacklistEntry(
            service: service,
            client: client,
            bundleID: bundleID,
            teamID: teamID,
            reason: reason
        )
        
        // Check if already blacklisted
        if !isBlacklisted(service: service, client: client) {
            blacklistedEntries.append(entry)
            saveBlacklist()
        }
    }
    
    func removeFromBlacklist(id: UUID) {
        blacklistedEntries.removeAll { $0.id == id }
        saveBlacklist()
    }
    
    func isBlacklisted(service: String, client: String) -> Bool {
        return blacklistedEntries.contains { entry in
            entry.service == service && entry.client == client
        }
    }
    
    func getBlacklistEntry(service: String, client: String) -> BlacklistEntry? {
        return blacklistedEntries.first { entry in
            entry.service == service && entry.client == client
        }
    }
    
    // MARK: - Revocation Attempts Management
    
    func logRevocationAttempt(service: String, client: String, bundleID: String?, blocked: Bool) {
        let attempt = RevocationAttempt(
            service: service,
            client: client,
            bundleID: bundleID,
            blocked: blocked
        )
        
        revocationAttempts.insert(attempt, at: 0) // Most recent first
        
        // Keep only last 1000 attempts
        if revocationAttempts.count > 1000 {
            revocationAttempts = Array(revocationAttempts.prefix(1000))
        }
        
        saveAttempts()
    }
    
    func clearAttempts() {
        revocationAttempts.removeAll()
        saveAttempts()
    }
    
    func clearOldAttempts(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        revocationAttempts.removeAll { $0.attemptedAt < cutoffDate }
        saveAttempts()
    }
    
    // MARK: - Persistence
    
    private func saveBlacklist() {
        if let encoded = try? JSONEncoder().encode(blacklistedEntries) {
            UserDefaults.standard.set(encoded, forKey: blacklistKey)
        }
    }
    
    private func loadBlacklist() {
        if let data = UserDefaults.standard.data(forKey: blacklistKey),
           let decoded = try? JSONDecoder().decode([BlacklistEntry].self, from: data) {
            blacklistedEntries = decoded
        }
    }
    
    private func saveAttempts() {
        if let encoded = try? JSONEncoder().encode(revocationAttempts) {
            UserDefaults.standard.set(encoded, forKey: attemptsKey)
        }
    }
    
    private func loadAttempts() {
        if let data = UserDefaults.standard.data(forKey: attemptsKey),
           let decoded = try? JSONDecoder().decode([RevocationAttempt].self, from: data) {
            revocationAttempts = decoded
        }
    }
}
