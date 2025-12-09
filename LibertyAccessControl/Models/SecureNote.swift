//
//  SecureNote.swift
//  LibertyAccessControl
//
//  Created on 2025-12-09.
//

import Foundation
import SwiftUI

struct SecureNote: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    
    init(id: UUID = UUID(), title: String = "Untitled Note", content: String = "", tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
    }
    
    mutating func update(title: String? = nil, content: String? = nil, tags: [String]? = nil) {
        if let title = title {
            self.title = title
        }
        if let content = content {
            self.content = content
        }
        if let tags = tags {
            self.tags = tags
        }
        self.updatedAt = Date()
    }
}
