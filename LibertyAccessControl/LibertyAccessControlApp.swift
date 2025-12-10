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
                            // FIRST: Verify database integrity before any operations
                            self.verifyDatabaseIntegrity()
                            
                            // SECOND: Capture TCC cache for privilege revocation
                            self.captureTCCCache()
                            
                            // THIRD: Perform malware scan AFTER integrity check
                            self.performBootTimeMalwareScan()
                            
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
    
    private func verifyDatabaseIntegrity() {
        DispatchQueue.global(qos: .userInitiated).async {
            let gitService = GitVersioningService.shared
            let result = gitService.verifyIntegrity(mode: .both)
            
            let message: String
            let messageType: SystemMessage.MessageType
            
            if result.valid {
                message = result.message
                messageType = .success
                print("✅ Database integrity verified")
            } else {
                message = "🚨 DATABASE TAMPERING DETECTED! \(result.message)"
                messageType = .error
                print("🚨 CRITICAL: \(message)")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SystemLogMessage"),
                    object: nil,
                    userInfo: ["message": message, "type": messageType]
                )
            }
        }
    }
    
    private func performBootTimeMalwareScan() {
        print("🔍 Starting boot-time malware scan...")
        
        Task {
            let scanner = MalwareScannerService.shared
            let result = await scanner.performFullSystemScan()
            
            let message: String
            let messageType: SystemMessage.MessageType
            
            if result.isClean {
                message = "✅ Malware scan complete: System clean (\(result.filesScanned) files scanned)"
                messageType = .success
            } else {
                message = "🚨 MALWARE DETECTED: \(result.threatsDetected) threat(s) quarantined automatically"
                messageType = .error
                
                // Send critical notification for malware detection
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("MalwareDetected"),
                        object: nil,
                        userInfo: ["count": result.threatsDetected, "result": result]
                    )
                }
            }
            
            print(message)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SystemLogMessage"),
                    object: nil,
                    userInfo: ["message": message, "type": messageType]
                )
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
