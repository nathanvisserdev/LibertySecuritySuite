//
//  LocAuthStat.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

enum LocAuthStat: Int, Codable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorizedAlways = 3
    
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        }
    }
    
    var isAuthorized: Bool {
        self == .authorizedAlways
    }
}
