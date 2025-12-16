//
//  PHAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Photos

/// Data Transfer Object for Photos authorization status
struct PHAuthStatDTO: Codable {
    let rawValue: Int
    
    init(from status: PHAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: PHAuthorizationStatus {
        PHAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}
