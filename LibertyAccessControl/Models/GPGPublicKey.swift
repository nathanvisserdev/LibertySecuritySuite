//
//  GPGPublicKey.swift
//  LibertyAccessControl
//

import Foundation

struct GPGPublicKey: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let keyASCII: String
    let addedDate: Date

    init(id: UUID = UUID(), name: String, keyASCII: String, addedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.keyASCII = keyASCII
        self.addedDate = addedDate
    }
}
