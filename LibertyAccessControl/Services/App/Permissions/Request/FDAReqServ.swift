//
//  FDAReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class FDAReqServ {
    func reqPerm() async throws -> Bool {
        // Full Disk Access cannot be programmatically requested
        // User must manually grant it in System Settings
        
        // Open System Settings to the Privacy & Security pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
        
        return false
    }
}
