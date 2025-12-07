//
//  UserPermissionsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class UserPermissionsViewModel: ObservableObject {
    @Published var statusMessage: String = "User TCC Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [TCCUserEntry] = []
    @Published var isLoading: Bool = false
    
    private let model: UserPermissionsModel
    
    init(userTCCDBService: UserTCCDBService = UserTCCDBService()) {
        self.model = UserPermissionsModel(userTCCDBService: userTCCDBService)
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Querying user TCC database..."
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.model.queryTCCDatabase()
            
            DispatchQueue.main.async {
                self.entries = result.entries
                self.isLoading = false
                
                if let error = result.error {
                    self.errorMessage = error
                }
                
                if result.entries.isEmpty {
                    self.statusMessage = "No user TCC entries found"
                } else {
                    let withTeamID = result.entries.filter { $0.parsedTeamID != nil }.count
                    let withCSReq = result.entries.filter { $0.csreq != nil }.count
                    self.statusMessage = "Loaded \(result.entries.count) user TCC entries (\(withCSReq) with csreq, \(withTeamID) with Team ID)"
                }
            }
        }
    }
}
