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
                    
                    // Start blacklist enforcement
                    BlacklistEnforcementService.shared.startMonitoring()
                    
                    // Perform initial security scan ASYNC (don't block UI)
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
                        self.performInitialSecurityScan()
                    }
                }
        }
    }
    
    private func performInitialSecurityScan() {
        let scanner = SuspiciousPermissionScanner()
        
        scanner.scanAllDatabases { suspiciousApps in
            guard !suspiciousApps.isEmpty else {
                print("✅ Security scan complete: No suspicious permissions detected")
                return
            }
            
            print("⚠️ Security scan found \(suspiciousApps.count) suspicious app(s)")
            
            // Auto-blacklist suspicious apps
            scanner.autoBlacklistSuspiciousApps(suspiciousApps: suspiciousApps) { count in
                print("🚫 Auto-blacklisted \(count) suspicious app(s) on launch")
                
                // Post notification to user
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SuspiciousAppsBlacklisted"),
                        object: nil,
                        userInfo: ["count": count]
                    )
                }
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
