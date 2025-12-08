//
//  SRRecServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class SRRecServ {
    func reqSRPerm() async throws -> (granted: Bool, message: String) {
        let hasAccess = CGPreflightScreenCaptureAccess()
        let result = CGRequestScreenCaptureAccess()
        
        let message = result ? "Screen Recording permission granted" : "Screen Recording permission denied - Check System Settings > Privacy & Security > Screen Recording"
        return (result, message)
    }
}
