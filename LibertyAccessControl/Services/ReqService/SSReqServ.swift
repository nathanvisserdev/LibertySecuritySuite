//
//  ScreenRecordingRecService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import ScreenCaptureKit

class SSReqServ {
    func reqPerm() async throws -> (granted: Bool, message: String) {
        do {
            let content = try await SCShareableContent.current
            let message = "Screen Sharing permission granted"
            return (true, message)
        } catch {
            return (false, "Screen Sharing permission denied: \(error.localizedDescription)")
        }
    }
    

    
    func checkSCPermission() async -> Bool {
        if #available(macOS 12.3, *) {
            // ScreenCaptureKit is the modern API (macOS 12.3+)
            do {
                let availableContent = try await SCShareableContent.current
                return !availableContent.displays.isEmpty
            } catch {
                return false
            }
        } else {
            // Fallback to CoreGraphics
            return quickScreenRecordingCheck()
        }
    }

}
