//
//  SRReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class SRReqServ {
    func reqPerm() async throws -> Bool {
        _ = CGPreflightScreenCaptureAccess()
        let result = CGRequestScreenCaptureAccess()
        return result
    }
}
