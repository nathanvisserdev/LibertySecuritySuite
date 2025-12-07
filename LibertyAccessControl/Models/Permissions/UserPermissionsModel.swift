//
//  UserPermissionsModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation

class UserPermissionsModel {
    
    private let userTCCDBService: UserTCCDBService
    
    init(userTCCDBService: UserTCCDBService) {
        self.userTCCDBService = userTCCDBService
    }
    
    func queryTCCDatabase() -> (entries: [TCCUserEntry], error: String?) {
        let result = userTCCDBService.queryEntries()
        
        guard let entries = result as? [TCCUserEntry] else {
            return ([], "Failed to query user TCC database. Make sure the app has Full Disk Access permission.")
        }
        
        return (entries, nil)
    }
}
