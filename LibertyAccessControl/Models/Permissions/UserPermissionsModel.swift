//
//  UserPermissionsModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-07.
//

import Foundation

class UserPermissionsModel {
    
    private let UserService: UserService
    
    init(UserService: UserService) {
        self.UserService = UserService
    }
    
    func queryTCCDatabase() -> (entries: [TCCUserEntry], error: String?) {
        let result = UserService.queryEntries()
        
        guard let entries = result as? [TCCUserEntry] else {
            return ([], "Failed to query user TCC database. Make sure the app has Full Disk Access permission.")
        }
        
        return (entries, nil)
    }
}
