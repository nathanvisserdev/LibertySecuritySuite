//
//  ScreenSharingViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class ScreenSharingViewModel: ObservableObject {
    @Published var isSharingEnabled: Bool = false
    @Published var statusMessage: String = "Screen sharing not enabled"
    @Published var errorMessage: String?
    
    func enableSharing() {
        isSharingEnabled = true
        statusMessage = "Screen sharing enabled"
        errorMessage = nil
    }
    
    func disableSharing() { 
        isSharingEnabled = false
        statusMessage = "Screen sharing disabled"
        errorMessage = nil
    }
}
