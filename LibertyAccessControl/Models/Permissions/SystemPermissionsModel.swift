//
//  SystemPermissionsModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation

class SystemPermissionsModel {
    private let systemTCCDBService: SystemTCCDBService
    
    init(systemTCCDBService: SystemTCCDBService = SystemTCCDBService()) {
        self.systemTCCDBService = systemTCCDBService
    }
    
    func queryTCCDatabase() -> (entries: [TCCSystemEntry], error: String?) {
        let entries = systemTCCDBService.queryEntries()
        
        if entries.isEmpty {
            return ([], "Failed to query system TCC database. Make sure the app has Full Disk Access permission.")
        }
        
        return (entries, nil)
    }
}
