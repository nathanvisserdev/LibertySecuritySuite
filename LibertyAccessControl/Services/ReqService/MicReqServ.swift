//
//  MicReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AVFoundation

class MicReqServ {
    func reqMicPerm() async throws -> (granted: Bool, message: String) {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        let message = granted ? "Microphone permission granted" : "Microphone permission denied"
        return (granted, message)
    }
}
