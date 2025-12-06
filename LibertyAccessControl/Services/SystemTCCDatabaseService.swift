//
//  SystemTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

class SystemTCCDatabaseService: BaseTCCDatabaseService, TCCDatabaseService {
    
    init() {
        super.init(dbPath: "/Library/Application Support/com.apple.TCC/TCC.db")
    }
    

}
