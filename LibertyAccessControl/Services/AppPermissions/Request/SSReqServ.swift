//
//  ScreenRecordingRecService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import ScreenCaptureKit

class SSReqServ {
    func reqPerm() async throws -> Bool {
        do {
            _ = try await SCShareableContent.current
            return true
        } catch {
            return false
        }
    }
}
