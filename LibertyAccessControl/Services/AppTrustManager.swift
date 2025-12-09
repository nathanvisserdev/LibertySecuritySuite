//
//  AppTrustManager.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Security

class AppTrustManager {
    static let shared = AppTrustManager()
    
    private init() {}
    
    /// Check if an app is trusted based on signature and system status
    func isAppTrusted(processName: String, bundleId: String?) -> Bool {
        // Check user's manual whitelist first
        if let bundleId = bundleId, MonitoringPreferences.shared.isAppTrusted(bundleId) {
            return true
        }
        
        // Check if it's a system app
        if isSystemApp(processName: processName, bundleId: bundleId) {
            return true
        }
        
        // Check if signed by Apple
        if let bundleId = bundleId, isAppleSigned(bundleId: bundleId) {
            return true
        }
        
        return false
    }
    
    /// Determine if an app is a system app
    private func isSystemApp(processName: String, bundleId: String?) -> Bool {
        // System process names
        let systemProcesses = [
            "WindowServer",
            "loginwindow",
            "SystemUIServer",
            "Finder",
            "Dock",
            "launchd",
            "kernel_task",
            "tccd",
            "syslogd"
        ]
        
        if systemProcesses.contains(where: { processName.contains($0) }) {
            return true
        }
        
        // Apple bundle IDs
        if let bundleId = bundleId {
            if bundleId.hasPrefix("com.apple.") {
                return true
            }
        }
        
        return false
    }
    
    /// Check if app is signed by Apple
    private func isAppleSigned(bundleId: String) -> Bool {
        // Get app path from bundle ID
        guard let appPath = getAppPath(for: bundleId) else {
            return false
        }
        
        // Check code signature
        var staticCode: SecStaticCode?
        let url = URL(fileURLWithPath: appPath)
        
        let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        // Verify signature
        let verifyStatus = SecStaticCodeCheckValidity(code, [], nil)
        if verifyStatus != errSecSuccess {
            return false
        }
        
        // Check if signed by Apple
        var requirement: SecRequirement?
        let requirementStatus = SecRequirementCreateWithString(
            "anchor apple" as CFString,
            [],
            &requirement
        )
        
        guard requirementStatus == errSecSuccess, let req = requirement else {
            return false
        }
        
        let matchStatus = SecStaticCodeCheckValidity(code, [], req)
        return matchStatus == errSecSuccess
    }
    
    /// Get app path from bundle identifier
    private func getAppPath(for bundleId: String) -> String? {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            return url.path
        }
        return nil
    }
    
    /// Extract bundle ID from process name (best effort)
    func getBundleId(from processName: String) -> String? {
        // Try to get running app by name
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        for app in runningApps {
            if let appName = app.localizedName, appName == processName {
                return app.bundleIdentifier
            }
            
            if let executableURL = app.executableURL?.lastPathComponent,
               executableURL == processName {
                return app.bundleIdentifier
            }
        }
        
        return nil
    }
    
    /// Get app information for trust decision UI
    func getAppInfo(processName: String) -> AppTrustInfo {
        let bundleId = getBundleId(from: processName)
        let isSystem = isSystemApp(processName: processName, bundleId: bundleId)
        let isApple = bundleId.map { isAppleSigned(bundleId: $0) } ?? false
        let isTrusted = bundleId.map { MonitoringPreferences.shared.isAppTrusted($0) } ?? false
        
        return AppTrustInfo(
            processName: processName,
            bundleId: bundleId,
            isSystemApp: isSystem,
            isAppleSigned: isApple,
            isUserTrusted: isTrusted
        )
    }
}

struct AppTrustInfo {
    let processName: String
    let bundleId: String?
    let isSystemApp: Bool
    let isAppleSigned: Bool
    let isUserTrusted: Bool
    
    var shouldAutoTrust: Bool {
        return isSystemApp || isAppleSigned
    }
    
    var trustStatus: String {
        if isUserTrusted { return "Trusted by User" }
        if isAppleSigned { return "Apple Signed" }
        if isSystemApp { return "System App" }
        return "Untrusted"
    }
}
