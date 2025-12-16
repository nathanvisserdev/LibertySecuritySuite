//
//  AVAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AVFoundation

/// Data Transfer Object for AVFoundation authorization status
struct AVAuthStatDTO: Codable {
    let rawValue: Int
    
    init(from status: AVAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: AVAuthorizationStatus {
        AVAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}