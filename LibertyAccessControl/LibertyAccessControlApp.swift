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
    @StateObject private var preferences = MonitoringPreferences()
    @StateObject private var monitoringService: ReqMonVM
    
    init() {
        // Create service dependencies
        let prefs = MonitoringPreferences()
        let trustManager = AppTrustManager(preferences: prefs)
        let parser = TCCLogParser()
        let notificationService = NotificationService(preferences: prefs, trustManager: trustManager)
        let systemMonitor = SystemMonitorService(parser: parser, notificationService: notificationService)
        
        // Inject services into monitoring service
        _preferences = StateObject(wrappedValue: prefs)
        _monitoringService = StateObject(wrappedValue: ReqMonVM(
            monitorService: systemMonitor,
            notificationService: notificationService
        ))
        
        // Register app to launch at login
        registerLaunchAtLogin()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(monitoringService)
                .onAppear {
                    // Start monitoring after environment is set up
                    monitoringService.startBackgroundMonitoring()
                }
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
