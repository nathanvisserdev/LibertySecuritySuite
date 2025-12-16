//
//  CamReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AVFoundation

class CamReqServ {
    func reqPerm() async throws -> AVAuthorizationStatus {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}
