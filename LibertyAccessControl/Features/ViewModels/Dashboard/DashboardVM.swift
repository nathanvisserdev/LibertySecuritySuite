//
//  DashboardVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import Combine

class DashboardVM: ObservableObject {
    @Published var statusMessage: String = "All Permissions - Ready to query"
    @Published var errorMessage: String?
    @Published var systemEntries: [SystemEntry] = []
    @Published var userEntries: [UserEntry] = []
    @Published var isLoading: Bool = false
    
    private let systemService: SystemService
    private let userService: UserService
    private let dashboardModel: DashboardModel
    
    init(systemService: SystemService, userService: UserService) {
        self.systemService = systemService
        self.userService = userService
        self.dashboardModel = DashboardModel()
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Loading all permissions..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let systemResults = self.dashboardModel.querySystemTCCDatabase()
            let userResults = self.dashboardModel.queryUserTCCDatabase()
            
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
            systemService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        } else {
            userService.updatePermission(service: service, client: client, authValue: authValue, completion: completion)
        }
    }
}
