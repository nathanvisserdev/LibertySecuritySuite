//
//  EKAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import EventKit

/// Data Transfer Object for EventKit authorization status
struct EKAuthStatDTO: Codable {
    let rawValue: Int
    
    init(from status: EKAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: EKAuthorizationStatus {
        EKAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}
