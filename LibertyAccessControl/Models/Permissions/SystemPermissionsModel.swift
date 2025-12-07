//
//  SystemPermissionsModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation

class SystemPermissionsModel {
    private let SystemService: SystemService
    
    init(SystemService: SystemService) {
        self.SystemService = SystemService
    }
    
    func queryTCCDatabase() -> (entries: [SystemEntry], error: String?) {
        let entries = SystemService.queryEntries()
        
        if entries.isEmpty {
            return ([], "Failed to query system TCC database. Make sure the app has Full Disk Access permission.")
        }
        
        return (entries, nil)
    }
}
