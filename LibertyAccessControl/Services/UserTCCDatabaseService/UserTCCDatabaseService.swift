//
//  UserTCCDatabaseService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-06.
//

import Foundation
import SQLite3

class UserTCCDatabaseService: BaseTCCDatabaseService, TCCDatabaseService {
    
    init() {
        super.init(dbPath: "\(NSHomeDirectory())/Library/Application Support/com.apple.TCC/TCC.db")
    }
    
    private func stopTCCD() {
        // Kill tccd without admin privileges for user database
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["-9", "tccd"]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("💀 tccd killed (user-level, exit code: \(process.terminationStatus))")
            Thread.sleep(forTimeInterval: 1.0)
        } catch {
            print("❌ Failed to kill tccd: \(error)")
        }
    }
}
