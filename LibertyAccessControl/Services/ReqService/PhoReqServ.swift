//
//  PhoReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Photos

class PhoReqServ {
    func reqPhoPerm() async throws -> (granted: Bool, message: String) {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized, .limited:
                    continuation.resume(returning: (true, "Photos permission granted"))
                case .denied, .restricted:
                    continuation.resume(returning: (false, "Photos permission denied"))
                case .notDetermined:
                    continuation.resume(returning: (false, "Photos permission not determined"))
                @unknown default:
                    continuation.resume(returning: (false, "Unknown photos permission status"))
                }
            }
        }
    }
}
