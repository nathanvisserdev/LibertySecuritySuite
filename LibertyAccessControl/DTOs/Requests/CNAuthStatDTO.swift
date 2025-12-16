//
//  CNAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Contacts

/// Data Transfer Object for Contacts authorization status
struct CNAuthStatDTO: Codable {
    let rawValue: Int
    
    init(from status: CNAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: CNAuthorizationStatus {
        CNAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}
