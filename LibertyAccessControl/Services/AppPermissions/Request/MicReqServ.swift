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
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
}
