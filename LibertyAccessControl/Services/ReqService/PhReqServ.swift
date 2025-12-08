//
//  PhReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Photos

class PhReqServ {
    func reqPerm() async throws -> PHAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
