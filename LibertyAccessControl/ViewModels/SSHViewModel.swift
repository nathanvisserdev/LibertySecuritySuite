//
//  SSHViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class SSHViewModel: ObservableObject {
    @Published var isSSHEnabled: Bool = false
    @Published var statusMessage: String = "SSH access not enabled"
    @Published var errorMessage: String?
    
    func enableSSH() {
        // SSH implementation will go here
        isSSHEnabled = true
        statusMessage = "SSH access enabled"
        errorMessage = nil
    }
    
    func disableSSH() {
        // Stop SSH
        isSSHEnabled = false
        statusMessage = "SSH access disabled"
        errorMessage = nil
    }
}
