//
//  FFReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import AppKit

class FFReqServ {
    func reqPerm() async throws -> Bool {
        // Files and Folders permission is granted via file picker
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a file or folder to grant access"
        
        return await withCheckedContinuation { continuation in
            openPanel.begin { response in
                continuation.resume(returning: response == .OK)
            }
        }
    }
}
