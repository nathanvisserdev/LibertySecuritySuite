//
//  ScreenRecordingRecService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import ScreenCaptureKit

class SSRecServ {
    func reqSSPerm() async throws -> (granted: Bool, message: String) {
        do {
            let content = try await SCShareableContent.current
            let message = "Screen Sharing permission granted"
            return (true, message)
        } catch {
            return (false, "Screen Sharing permission denied: \(error.localizedDescription)")
        }
    }
}
