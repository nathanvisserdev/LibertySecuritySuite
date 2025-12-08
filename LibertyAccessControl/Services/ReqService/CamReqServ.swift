//
//  CamReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AVFoundation

class CamReqServ {
    func reqCamPerm() async throws -> (granted: Bool, message: String) {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        let message = granted ? "Camera permission granted" : "Camera permission denied"
        return (granted, message)
    }
}
