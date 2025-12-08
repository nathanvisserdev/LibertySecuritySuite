//
//  UNAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import UserNotifications

/// Data Transfer Object for UserNotifications authorization status
struct UNAuthStatDTO: Codable {
    let rawValue: Int
    
    init(from status: UNAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: UNAuthorizationStatus {
        UNAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}
