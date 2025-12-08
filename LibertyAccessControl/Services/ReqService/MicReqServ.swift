//
//  MicReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AVFoundation

class MicReqServ {
    func reqPerm() async throws -> AVAuthorizationStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        let message = granted ? "Microphone permission granted" : "Microphone permission denied"
        return (granted, message)
    }
}
