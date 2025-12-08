//
//  FDAReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class FDAReqServ {
    func reqPerm() async throws -> (granted: Bool, message: String) {
        // Full Disk Access cannot be programmatically requested
        // User must manually grant it in System Settings
        let message = "Full Disk Access must be manually enabled in System Settings > Privacy & Security > Full Disk Access"
        
        // Open System Settings to the Privacy & Security pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
        
        return (false, message)
    }
}
