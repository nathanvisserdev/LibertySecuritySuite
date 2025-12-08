//
//  AEReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class AEReqServ {
    func reqAEPerm() async throws -> (granted: Bool, message: String) {
        // Apple Events (Automation) permission must be manually granted
        // Open System Settings to Privacy & Security > Automation
        let message = "Apple Events (Automation) permission must be manually enabled in System Settings > Privacy & Security > Automation"
        
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
        
        return (false, message)
    }
}
