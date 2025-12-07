//
//  SystemVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class SystemVM: ObservableObject {
    @Published var statusMessage: String = "System TCC Database - Ready to query"
    @Published var errorMessage: String?
    @Published var entries: [SystemEntry] = []
    @Published var isLoading: Bool = false
    
    private let model: SystemPermissionsModel
    
    init(model: SystemPermissionsModel = SystemPermissionsModel(SystemService: SystemService())) {
        self.model = model
    }
    
    func loadTCCData() {
        isLoading = true
        statusMessage = "Loading system TCC database..."
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
                    self.statusMessage = "No system TCC entries found"
                } else {
                    self.statusMessage = "Loaded \(result.entries.count) system TCC entries"
                }
            }
        }
    }
}
