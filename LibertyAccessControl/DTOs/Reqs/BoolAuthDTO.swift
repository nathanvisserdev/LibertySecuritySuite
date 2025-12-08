//
//  BoolAuthDTO.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

/// Data Transfer Object for boolean authorization responses
struct BoolAuthDTO: Codable {
    let granted: Bool
    
    init(from granted: Bool) {
        self.granted = granted
    }
}
