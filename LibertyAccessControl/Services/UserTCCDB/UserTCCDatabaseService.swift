//
//  UserTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

let userDBPath = "\(NSHomeDirectory())/Library/Application Support/com.apple.TCC/TCC.db"

class UserTCCDatabaseService: BaseTCCDatabaseService, TCCDatabaseService {
    
    init() {
        super.init(dbPath: userDBPath)
    }
}
