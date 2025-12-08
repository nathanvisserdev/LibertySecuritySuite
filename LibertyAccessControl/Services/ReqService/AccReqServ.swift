//
//  AccReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import ApplicationServices
import AppKit

class AccReqServ {
    func reqPerm() async throws -> (granted: Bool, message: String) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        let message = trusted ? "Accessibility permission granted" : "Accessibility permission denied - Check System Settings > Privacy & Security > Accessibility"
        
        if !trusted {
            // Open System Settings to Privacy & Security > Accessibility
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        
        return (trusted, message)
    }
}
