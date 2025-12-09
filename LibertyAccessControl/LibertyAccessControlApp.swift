//
//  LibertyAccessControlApp.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import SwiftUI
import ServiceManagement

@main
struct LibertyAccessControlApp: App {
    @StateObject private var monitoringService = NotificationsViewModel.shared
    
    init() {
        // Register app to launch at login
        registerLaunchAtLogin()
        
        // Start monitoring automatically on launch
        NotificationsViewModel.shared.startBackgroundMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitoringService)
        }
    }
    
    private func registerLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                // Modern API for macOS 13+
                try SMAppService.mainApp.register()
            } catch {
                print("Failed to register login item: \(error.localizedDescription)")
            }
        } else {
            // Fallback for older macOS versions
            // Note: SMLoginItemSetEnabled is deprecated but necessary for macOS 12 and earlier
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "LibertyAccessControl"
            SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
        }
    }
}
