//
//  RemoteManagementViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class RemoteManagementViewModel: ObservableObject {
    @Published var isManagementEnabled: Bool = false
    @Published var statusMessage: String = "Remote management not enabled"
    @Published var errorMessage: String?
    
    func enableManagement() {
        // Remote management implementation will go here
        isManagementEnabled = true
        statusMessage = "Remote management enabled"
        errorMessage = nil
    }
    
    func disableManagement() {
        // Stop remote management
        isManagementEnabled = false
        statusMessage = "Remote management disabled"
        errorMessage = nil
    }
}
