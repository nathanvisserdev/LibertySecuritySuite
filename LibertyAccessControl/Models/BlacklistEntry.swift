//
//  BlacklistEntry.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

struct BlacklistEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let service: String
    let client: String
    let bundleID: String?
    let teamID: String?
    let revokedAt: Date
    let reason: String?
    
    init(id: UUID = UUID(), service: String, client: String, bundleID: String?, teamID: String?, revokedAt: Date = Date(), reason: String? = nil) {
        self.id = id
        self.service = service
        self.client = client
        self.bundleID = bundleID
        self.teamID = teamID
        self.revokedAt = revokedAt
        self.reason = reason
    }
    
    static func == (lhs: BlacklistEntry, rhs: BlacklistEntry) -> Bool {
        lhs.id == rhs.id
    }
}

struct RevocationAttempt: Identifiable, Codable, Equatable {
    let id: UUID
    let service: String
    let client: String
    let bundleID: String?
    let attemptedAt: Date
    let blocked: Bool
    
    init(id: UUID = UUID(), service: String, client: String, bundleID: String?, attemptedAt: Date = Date(), blocked: Bool) {
        self.id = id
        self.service = service
        self.client = client
        self.bundleID = bundleID
        self.attemptedAt = attemptedAt
        self.blocked = blocked
    }
    
    static func == (lhs: RevocationAttempt, rhs: RevocationAttempt) -> Bool {
        lhs.id == rhs.id
    }
}
