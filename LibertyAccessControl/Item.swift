//
//  Item.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var content: String
    
    init(timestamp: Date, content: String = "") {
        self.timestamp = timestamp
        self.content = content
    }
}
