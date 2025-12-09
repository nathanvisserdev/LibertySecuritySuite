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
    @StateObject private var authState = AuthenticationState()
    @StateObject private var blacklistEnforcementService: BlacklistEnforcementService
    
    init() {
        // Create service dependencies
        let prefs = MonitoringPreferences()
        let trustManager = AppTrustManager(preferences: prefs)
        let parser = TCCLogParser()
        let notificationService = NotificationService(preferences: prefs, trustManager: trustManager)
        let systemMonitor = SystemMonitorService(parser: parser, notificationService: notificationService)
        let systemService = SystemService()
        let userService = UserService()
        let blacklistEnforcement = BlacklistEnforcementService(systemService: systemService, userService: userService)
        
        // Inject services into monitoring service
        _preferences = StateObject(wrappedValue: prefs)
        _monitoringService = StateObject(wrappedValue: ReqMonVM(
            monitorService: systemMonitor,
            notificationService: notificationService
        ))
        _blacklistEnforcementService = StateObject(wrappedValue: blacklistEnforcement)
        
        // Register app to launch at login
        registerLaunchAtLogin()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authState.status == .authenticated {
                    ContentView()
                        .environmentObject(preferences)
                        .environmentObject(monitoringService)
                        .environmentObject(blacklistEnforcementService)
                        .onAppear {
                            // FIRST: Capture TCC cache for privilege revocation
                            self.captureTCCCache()
                            
                            // Start monitoring after environment is set up
                            monitoringService.startBackgroundMonitoring()
                            
                            // Start blacklist enforcement
                            blacklistEnforcementService.startMonitoring()
                            
                            // Perform initial security scan ASYNC (don't block UI)
                            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
                                self.performInitialSecurityScan()
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button(action: {
                                    authState.logout()
                                }) {
                                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        }
                } else {
                    AuthenticationView()
                        .environmentObject(authState)
                }
            }
            .environmentObject(authState)
            .onAppear {
                authState.checkAuthenticationStatus()
            }
        }
    }
    
    private func captureTCCCache() {
        DispatchQueue.global(qos: .userInitiated).async {
            TCCCacheReader.shared.captureCache { result in
                switch result {
                case .success(let info):
                    let successMsg = "✅ TCC cache captured successfully"
                    print(successMsg)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SystemLogMessage"),
                            object: nil,
                            userInfo: ["message": successMsg, "type": SystemMessage.MessageType.success]
                        )
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SystemLogMessage"),
                            object: nil,
                            userInfo: ["message": info, "type": SystemMessage.MessageType.info]
                        )
                    }
                    
                case .failure(let error):
                    let errorMsg = "❌ TCC cache capture failed: \(error.localizedDescription)"
                    print(errorMsg)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SystemLogMessage"),
                            object: nil,
                            userInfo: ["message": errorMsg, "type": SystemMessage.MessageType.error]
                        )
                    }
                }
            }
        }
    }
    
    private func performInitialSecurityScan() {
        let scanner = SuspiciousPermissionScanner()
        
        scanner.scanAllDatabases { suspiciousApps in
            guard !suspiciousApps.isEmpty else {
                let message = "✅ Security scan complete: No suspicious permissions detected"
                print(message)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SystemLogMessage"),
                        object: nil,
                        userInfo: ["message": message, "type": SystemMessage.MessageType.success]
                    )
                }
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
