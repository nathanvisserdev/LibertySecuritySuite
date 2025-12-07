//
//  PermissionsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import Combine

class PermissionsViewModel: ObservableObject {
    @Published var statusMessage: String = "All Permissions - Ready to query"
    @Published var errorMessage: String?
    @Published var systemEntries: [TCCSystemEntry] = []
    @Published var userEntries: [TCCUserEntry] = []
    @Published var isLoading: Bool = false
    
    private let systemDBService: SystemService
    private let userDBService: UserTCCDBService
    private let permissionsModel: PermissionsModel
    
    init(systemDBService: SystemService, userDBService: UserTCCDBService, permissionsModel: PermissionsModel = PermissionsModel()) {
        self.systemDBService = systemDBService
        self.userDBService = userDBService
        self.permissionsModel = permissionsModel
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Loading all permissions..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let systemResults = self.permissionsModel.querySystemTCCDatabase()
            let userResults = self.permissionsModel.queryUserTCCDatabase()
            
            DispatchQueue.main.async {
                self.systemEntries = systemResults
                self.userEntries = userResults
                self.isLoading = false
                self.statusMessage = "Loaded \(systemResults.count) system entries and \(userResults.count) user entries"
            }
        }
    }
    
    func updatePermission(service: String, client: String, authValue: Int, isSystemDB: Bool, completion: @escaping (Bool, String) -> Void) {
        if isSystemDB {
            systemDBService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        } else {
            userDBService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        }
    }
}
