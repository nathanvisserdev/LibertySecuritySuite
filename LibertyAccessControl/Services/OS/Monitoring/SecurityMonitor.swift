//
//  SecurityMonitor.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import Foundation
import Combine

/// Monitors critical system locations for suspicious activity and tampering
class SecurityMonitor: ObservableObject {
    @Published var threats: [SecurityThreat] = []
    @Published var isMonitoring: Bool = false
    @Published var lastScanDate: Date?
    @Published var statusMessage: String = "Not monitoring"
    
    private var monitoringTimer: Timer?
    private let fileManager = FileManager.default
    
    // Critical paths to monitor
    private let criticalPaths = [
        // Launch Agents/Daemons
        "/Library/LaunchAgents",
        "/Library/LaunchDaemons",
        "/System/Library/LaunchAgents",
        "/System/Library/LaunchDaemons",
        "~/Library/LaunchAgents",
        
        // System Extensions
        "/Library/SystemExtensions",
        "/System/Library/Extensions",
        
        // Application Support
        "/Library/Application Support",
        "~/Library/Application Support",
        
        // Startup Items
        "/Library/StartupItems",
        "/System/Library/StartupItems",
        
        // Preferences
        "/Library/Preferences",
        "~/Library/Preferences",
        
        // Scripts folders
        "/Library/Scripts",
        "/usr/local/bin",
        
        // Cron
        "/etc/crontab",
        "/var/at/tabs",
        
        // Kernel extensions (deprecated but still check)
        "/Library/Extensions",
        "/System/Library/Extensions"
    ]
    
    // Known safe bundle IDs (whitelist)
    private let trustedBundleIDs = [
        "com.apple.",
        "com.libertyaccesscontrol.",
        // Add more trusted prefixes
    ]
    
    func startMonitoring(interval: TimeInterval = 300) { // Default: 5 minutes
        guard !isMonitoring else { return }
        
        isMonitoring = true
        statusMessage = "Monitoring active"
        
        // Initial scan
        performSecurityScan()
        
        // Schedule periodic scans
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performSecurityScan()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        statusMessage = "Monitoring stopped"
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func performSecurityScan() {
        statusMessage = "Scanning system..."
        var detectedThreats: [SecurityThreat] = []
        
        // Check each critical path
        for path in criticalPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            detectedThreats.append(contentsOf: scanPath(expandedPath))
        }
        
        // Check for suspicious processes
        detectedThreats.append(contentsOf: scanRunningProcesses())
        
        // Check TCC database for unauthorized entries
        detectedThreats.append(contentsOf: scanTCCDatabase())
        
        // Check for suspicious kernel extensions
        detectedThreats.append(contentsOf: scanKernelExtensions())
        
        // Update threats
        DispatchQueue.main.async {
            self.threats = detectedThreats
            self.lastScanDate = Date()
            self.statusMessage = detectedThreats.isEmpty ? 
                "✓ No threats detected" : 
                "⚠️ \(detectedThreats.count) potential threat(s) detected"
        }
    }
    
    private func scanPath(_ path: String) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        guard fileManager.fileExists(atPath: path) else {
            return threats
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
                    continue
                }
                
                // Check file attributes
                let attributes = try? fileManager.attributesOfItem(atPath: itemPath)
                let modificationDate = attributes?[.modificationDate] as? Date
                let creationDate = attributes?[.creationDate] as? Date
                
                // Check if recently modified (within last 24 hours)
                let recentlyModified = modificationDate.map { Date().timeIntervalSince($0) < 86400 } ?? false
                
                // Check if executable
                let isExecutable = fileManager.isExecutableFile(atPath: itemPath)
                
                // Check plist files for suspicious launch agents/daemons
                if item.hasSuffix(".plist") {
                    if let threat = analyzePlistFile(at: itemPath, recentlyModified: recentlyModified) {
                        threats.append(threat)
                    }
                }
                
                // Check for suspicious executables
                if isExecutable && !isDirectory.boolValue {
                    if let threat = analyzeExecutable(at: itemPath, recentlyModified: recentlyModified) {
                        threats.append(threat)
                    }
                }
                
                // Check for hidden files in suspicious locations
                if item.hasPrefix(".") && path.contains("LaunchAgents") || path.contains("LaunchDaemons") {
                    threats.append(SecurityThreat(
                        type: .suspiciousFile,
                        severity: .medium,
                        location: itemPath,
                        description: "Hidden file in launch directory",
                        detectedAt: Date(),
                        details: "Filename: \(item)"
                    ))
                }
            }
        } catch {
            // Permission denied or other error
        }
        
        return threats
    }
    
    private func analyzePlistFile(at path: String, recentlyModified: Bool) -> SecurityThreat? {
        guard let plistData = fileManager.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        var suspicionLevel = 0
        var reasons: [String] = []
        
        // Check for suspicious program arguments
        if let programArguments = plist["ProgramArguments"] as? [String] {
            for arg in programArguments {
                if arg.contains("curl") || arg.contains("wget") || arg.contains("/tmp") || 
                   arg.contains("bash -c") || arg.contains("sh -c") || arg.contains("eval") {
                    suspicionLevel += 2
                    reasons.append("Suspicious command: \(arg)")
                }
            }
        }
        
        // Check for suspicious program path
        if let program = plist["Program"] as? String {
            if program.contains("/tmp") || program.contains("/var/tmp") {
                suspicionLevel += 3
                reasons.append("Program in temporary directory: \(program)")
            }
        }
        
        // Check Label for non-standard bundle ID
        if let label = plist["Label"] as? String {
            let isTrusted = trustedBundleIDs.contains { label.hasPrefix($0) }
            if !isTrusted {
                suspicionLevel += 1
                reasons.append("Untrusted bundle ID: \(label)")
            }
        }
        
        // Check if RunAtLoad is enabled
        if let runAtLoad = plist["RunAtLoad"] as? Bool, runAtLoad {
            suspicionLevel += 1
            reasons.append("Auto-starts at boot")
        }
        
        // Check for KeepAlive
        if let keepAlive = plist["KeepAlive"] as? Bool, keepAlive {
            suspicionLevel += 1
            reasons.append("Persistent process (KeepAlive)")
        }
        
        // Recently modified increases suspicion
        if recentlyModified {
            suspicionLevel += 2
            reasons.append("Recently modified (within 24 hours)")
        }
        
        if suspicionLevel >= 3 {
            return SecurityThreat(
                type: .suspiciousLaunchAgent,
                severity: suspicionLevel >= 5 ? .high : .medium,
                location: path,
                description: "Suspicious launch agent/daemon detected",
                detectedAt: Date(),
                details: reasons.joined(separator: "\n")
            )
        }
        
        return nil
    }
    
    private func analyzeExecutable(at path: String, recentlyModified: Bool) -> SecurityThreat? {
        // Check if in suspicious location
        let suspiciousLocations = ["/tmp", "/var/tmp", "/private/tmp"]
        let isSuspiciousLocation = suspiciousLocations.contains { path.hasPrefix($0) }
        
        // Check code signature
        let isCodeSigned = checkCodeSignature(path: path)
        
        if isSuspiciousLocation || (!isCodeSigned && recentlyModified) {
            return SecurityThreat(
                type: .unauthorizedExecutable,
                severity: isSuspiciousLocation ? .high : .medium,
                location: path,
                description: "Suspicious executable detected",
                detectedAt: Date(),
                details: [
                    isSuspiciousLocation ? "Located in temporary directory" : nil,
                    !isCodeSigned ? "Not code signed" : nil,
                    recentlyModified ? "Recently created/modified" : nil
                ].compactMap { $0 }.joined(separator: "\n")
            )
        }
        
        return nil
    }
    
    private func checkCodeSignature(path: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-v", path]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func scanRunningProcesses() -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    // Look for suspicious patterns
                    if line.contains("/tmp") && (line.contains("bash") || line.contains("sh")) {
                        threats.append(SecurityThreat(
                            type: .suspiciousProcess,
                            severity: .high,
                            location: "Process",
                            description: "Suspicious process running from /tmp",
                            detectedAt: Date(),
                            details: line.trimmingCharacters(in: .whitespaces)
                        ))
                    }
                    
                    if line.contains("nc ") || line.contains("netcat") {
                        threats.append(SecurityThreat(
                            type: .suspiciousProcess,
                            severity: .high,
                            location: "Process",
                            description: "Netcat process detected (potential backdoor)",
                            detectedAt: Date(),
                            details: line.trimmingCharacters(in: .whitespaces)
                        ))
                    }
                }
            }
        } catch {
            // Error scanning processes
        }
        
        return threats
    }
    
    private func scanTCCDatabase() -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        let userService = UserService()
        let systemService = SystemService()
        
        // Get all TCC entries
        let userEntries = userService.queryEntries() as? [UserEntry] ?? []
        let systemEntries = systemService.queryEntries()
        
        // Check for suspicious entries (recently added with powerful permissions)
        let now = Date()
        
        for entry in userEntries {
            if let lastModified = entry.last_modified,
               now.timeIntervalSince(lastModified) < 86400, // Within 24 hours
               entry.auth_value == 2 { // Granted
                
                let isTrusted = trustedBundleIDs.contains { entry.client.hasPrefix($0) }
                
                if !isTrusted {
                    threats.append(SecurityThreat(
                        type: .unauthorizedTCCEntry,
                        severity: .medium,
                        location: "TCC Database (User)",
                        description: "Recently granted permission to untrusted app",
                        detectedAt: Date(),
                        details: "App: \(entry.client)\nService: \(entry.service)"
                    ))
                }
            }
        }
        
        return threats
    }
    
    private func scanKernelExtensions() -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/kextstat")
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    // Check for non-Apple kernel extensions
                    if !line.contains("com.apple.") && line.contains("(") {
                        threats.append(SecurityThreat(
                            type: .suspiciousKernelExtension,
                            severity: .medium,
                            location: "Kernel",
                            description: "Third-party kernel extension loaded",
                            detectedAt: Date(),
                            details: line.trimmingCharacters(in: .whitespaces)
                        ))
                    }
                }
            }
        } catch {
            // Error scanning kernel extensions
        }
        
        return threats
    }
    
    func quarantineThreat(_ threat: SecurityThreat) {
        // Move file to quarantine location
        let quarantinePath = NSHomeDirectory() + "/Library/Application Support/LibertyAccessControl/Quarantine"
        
        do {
            try fileManager.createDirectory(atPath: quarantinePath, withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: threat.location) {
                let filename = (threat.location as NSString).lastPathComponent
                let destinationPath = (quarantinePath as NSString).appendingPathComponent(filename)
                
                try fileManager.moveItem(atPath: threat.location, toPath: destinationPath)
                
                // Remove from threats
                DispatchQueue.main.async {
                    self.threats.removeAll { $0.id == threat.id }
                    self.statusMessage = "Threat quarantined: \(filename)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Failed to quarantine: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteThreat(_ threat: SecurityThreat) {
        do {
            if fileManager.fileExists(atPath: threat.location) {
                try fileManager.removeItem(atPath: threat.location)
                
                DispatchQueue.main.async {
                    self.threats.removeAll { $0.id == threat.id }
                    self.statusMessage = "Threat deleted"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }
    
    func ignoreThreat(_ threat: SecurityThreat) {
        DispatchQueue.main.async {
            self.threats.removeAll { $0.id == threat.id }
        }
    }
}

// MARK: - Models

struct SecurityThreat: Identifiable, Equatable {
    let id = UUID()
    let type: ThreatType
    let severity: ThreatSeverity
    let location: String
    let description: String
    let detectedAt: Date
    let details: String
    
    static func == (lhs: SecurityThreat, rhs: SecurityThreat) -> Bool {
        lhs.id == rhs.id
    }
}

enum ThreatType: String {
    case suspiciousLaunchAgent = "Suspicious Launch Agent"
    case suspiciousFile = "Suspicious File"
    case unauthorizedExecutable = "Unauthorized Executable"
    case suspiciousProcess = "Suspicious Process"
    case unauthorizedTCCEntry = "Unauthorized TCC Entry"
    case suspiciousKernelExtension = "Kernel Extension"
    case tampering = "System Tampering"
}

enum ThreatSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
