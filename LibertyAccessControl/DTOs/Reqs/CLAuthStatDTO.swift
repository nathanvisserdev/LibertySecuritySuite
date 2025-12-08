//
//  CLAuthStatDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import CoreLocation

struct CLAuthStatDTO: Codable {
    let rawValue: Int32
    
    init(from status: CLAuthorizationStatus) {
        self.rawValue = status.rawValue
    }
    
    var status: CLAuthorizationStatus {
        CLAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
    }
}
