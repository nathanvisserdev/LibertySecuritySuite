//
//  NetworkMonitor.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-09.
//

import Foundation
import Network
import Combine

/// Monitors network connections and firewall activity
class NetworkMonitor: ObservableObject {
    @Published var activeConnections: [NetworkConnection] = []
    @Published var blockedConnections: [BlockedConnection] = []
    @Published var isMonitoring: Bool = false
    @Published var statusMessage: String = "Network monitoring inactive"
    @Published var firewallEnabled: Bool = false
    @Published var isAuthorized: Bool = false
    
    private var monitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "com.libertyaccesscontrol.networkmonitor")
    private var connectionCheckTimer: Timer?
    private let fileManager = FileManager.default
    private let authService = AuthorizationService()
    
    // Suspicious indicators
    private let suspiciousPorts: Set<UInt16> = [
        22, 23, 25, 110, 143, 445, 1433, 3306, 3389, 5432, 5900, 6379, 8080, 8888, 9000
    ]
    
    private let knownMaliciousIPs: Set<String> = [] // Can be populated from threat intelligence
    
    private var blockedIPs: Set<String> = []
    private var blockedDomains: Set<String> = []
    private var applicationRules: [String: FirewallRule] = [:] // Bundle ID -> Rule
    
    init() {
        loadFirewallRules()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        statusMessage = "Authenticating..."
        
        authService.authenticateWithBiometrics(reason: "Authenticate to manage firewall settings") { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.statusMessage = "Biometric authorization granted"
                    self.checkFirewallStatus()
                } else {
                    self.isAuthorized = false
                    self.statusMessage = "Authorization failed: \(error ?? "Unknown error")"
                }
            }
        }
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        statusMessage = "Network monitoring active"
        
        // Start network path monitoring
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        monitor?.start(queue: monitorQueue)
        
        // Start periodic connection checks
        startConnectionMonitoring()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        statusMessage = "Network monitoring stopped"
        monitor?.cancel()
        monitor = nil
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = nil
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        DispatchQueue.main.async {
            if path.status == .satisfied {
                self.statusMessage = "Network connected - monitoring active"
            } else {
                self.statusMessage = "Network disconnected"
            }
        }
    }
    
    // MARK: - Connection Monitoring
    
    private func startConnectionMonitoring() {
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.scanActiveConnections()
        }
    }
    
    private func scanActiveConnections() {
        Task {
            let connections = await fetchActiveConnections()
            let suspicious = connections.filter { isSuspicious($0) }
            
            await MainActor.run {
                self.activeConnections = connections
                
                // Auto-block suspicious connections
                for connection in suspicious {
                    if shouldBlock(connection) {
                        blockConnection(connection)
                    }
                }
            }
        }
    }
    
    private func fetchActiveConnections() async -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        
        // Use netstat to get active connections
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        task.arguments = ["-an", "-p", "tcp"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Catch errors
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    connections = parseNetstatOutput(output)
                }
            }
        } catch {
            // Error running netstat - not critical, just means we can't get connections
        }
        
        // Also get process-specific connections
        connections.append(contentsOf: await fetchProcessConnections())
        
        return connections
    }
    
    private func parseNetstatOutput(_ output: String) -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines.dropFirst() { // Skip header
            let components = line.split(separator: " ").map { String($0) }.filter { !$0.isEmpty }
            guard components.count >= 5 else { continue }
            
            let proto = components[0]
            let localAddress = components[3]
            let foreignAddress = components[4]
            let state = components.count > 5 ? components[5] : ""
            
            // Parse addresses
            let localParts = localAddress.split(separator: ".")
            let foreignParts = foreignAddress.split(separator: ".")
            
            guard localParts.count >= 2, foreignParts.count >= 2 else { continue }
            
            let localIP = localParts.dropLast().joined(separator: ".")
            let localPort = UInt16(localParts.last ?? "0") ?? 0
            let foreignIP = foreignParts.dropLast().joined(separator: ".")
            let foreignPort = UInt16(foreignParts.last ?? "0") ?? 0
            
            if foreignIP != "*" && foreignPort > 0 {
                connections.append(NetworkConnection(
                    id: UUID(),
                    processName: "Unknown",
                    processID: 0,
                    bundleID: nil,
                    protocol: proto,
                    localAddress: localIP,
                    localPort: localPort,
                    remoteAddress: foreignIP,
                    remotePort: foreignPort,
                    state: state,
                    direction: .outbound,
                    timestamp: Date()
                ))
            }
        }
        
        return connections
    }
    
    private func fetchProcessConnections() async -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        
        // Use lsof to get process-specific connections
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-i", "-n", "-P"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Catch errors
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    connections = parseLsofOutput(output)
                }
            }
        } catch {
            // Error running lsof (requires elevated privileges) - not critical
        }
        
        return connections
    }
    
    private func parseLsofOutput(_ output: String) -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines.dropFirst() {
            let components = line.split(separator: " ").map { String($0) }.filter { !$0.isEmpty }
            guard components.count >= 9 else { continue }
            
            let processName = components[0]
            let pid = Int(components[1]) ?? 0
            let type = components[4]
            let node = components[7]
            let name = components[8]
            
            // Parse connection info
            if name.contains("->") {
                let parts = name.split(separator: "->").map { String($0) }
                if parts.count == 2 {
                    let local = parseAddressPort(parts[0])
                    let remote = parseAddressPort(parts[1])
                    
                    connections.append(NetworkConnection(
                        id: UUID(),
                        processName: processName,
                        processID: pid,
                        bundleID: getBundleID(forPID: pid),
                        protocol: type,
                        localAddress: local.address,
                        localPort: local.port,
                        remoteAddress: remote.address,
                        remotePort: remote.port,
                        state: "ESTABLISHED",
                        direction: .outbound,
                        timestamp: Date()
                    ))
                }
            }
        }
        
        return connections
    }
    
    private func parseAddressPort(_ string: String) -> (address: String, port: UInt16) {
        let parts = string.split(separator: ":")
        if parts.count == 2 {
            return (String(parts[0]), UInt16(parts[1]) ?? 0)
        }
        return (string, 0)
    }
    
    private func getBundleID(forPID pid: Int) -> String? {
        // Get bundle ID from running process
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", "\(pid)", "-o", "comm="]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                // Try to get bundle from app path
                if let bundle = Bundle(path: path) {
                    return bundle.bundleIdentifier
                }
            }
        } catch {}
        
        return nil
    }
    
    // MARK: - Threat Detection
    
    private func isSuspicious(_ connection: NetworkConnection) -> Bool {
        var suspicionScore = 0
        
        // Check suspicious ports
        if suspiciousPorts.contains(connection.remotePort) {
            suspicionScore += 2
        }
        
        // Check for connections to private IPs (possible lateral movement)
        if isPrivateIP(connection.remoteAddress) && connection.remotePort != 80 && connection.remotePort != 443 {
            suspicionScore += 1
        }
        
        // Check known malicious IPs
        if knownMaliciousIPs.contains(connection.remoteAddress) {
            suspicionScore += 5
        }
        
        // Check for unusual ports
        if connection.remotePort > 49152 { // Dynamic/private ports
            suspicionScore += 1
        }
        
        // Check process name for suspicious patterns
        if connection.processName.contains("tmp") || connection.processName.hasPrefix(".") {
            suspicionScore += 3
        }
        
        return suspicionScore >= 3
    }
    
    private func isPrivateIP(_ ip: String) -> Bool {
        return ip.hasPrefix("10.") || 
               ip.hasPrefix("192.168.") || 
               ip.hasPrefix("172.16.") ||
               ip.hasPrefix("127.")
    }
    
    private func shouldBlock(_ connection: NetworkConnection) -> Bool {
        // Check if IP is in block list
        if blockedIPs.contains(connection.remoteAddress) {
            return true
        }
        
        // Check application-specific rules
        if let bundleID = connection.bundleID,
           let rule = applicationRules[bundleID] {
            return !rule.allowed
        }
        
        // Auto-block highly suspicious connections
        return isSuspicious(connection) && connection.processName != "safari" && connection.processName != "chrome"
    }
    
    // MARK: - Firewall Management
    
    func checkFirewallStatus() {
        guard isAuthorized else { return }
        
        let result = authService.executeWithAdminPrompt(command: "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate")
        
        DispatchQueue.main.async {
            if result.success {
                self.firewallEnabled = result.output.contains("enabled")
            } else {
                self.statusMessage = "Unable to check firewall status"
            }
        }
    }
    
    func enableFirewall() {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.statusMessage = "Authorization required to enable firewall"
            }
            return
        }
        
        let result = authService.executeWithAdminPrompt(command: "/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on")
        
        DispatchQueue.main.async {
            if result.success {
                self.statusMessage = "Firewall enabled"
                self.checkFirewallStatus()
            } else {
                self.statusMessage = "Failed to enable firewall"
            }
        }
    }
    
    func disableFirewall() {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.statusMessage = "Authorization required to disable firewall"
            }
            return
        }
        
        let result = authService.executeWithAdminPrompt(command: "/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off")
        
        DispatchQueue.main.async {
            if result.success {
                self.statusMessage = "Firewall disabled"
                self.checkFirewallStatus()
            } else {
                self.statusMessage = "Failed to disable firewall"
            }
        }
    }
    
    func blockApplication(bundleID: String) {
        applicationRules[bundleID] = FirewallRule(bundleID: bundleID, allowed: false)
        saveFirewallRules()
    }
    
    func allowApplication(bundleID: String) {
        applicationRules[bundleID] = FirewallRule(bundleID: bundleID, allowed: true)
        saveFirewallRules()
    }
    
    func blockIP(_ ip: String) {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.statusMessage = "Authorization required to block IPs"
            }
            return
        }
        
        blockedIPs.insert(ip)
        
        // Use pfctl to block IP
        let result = authService.executeWithAdminPrompt(command: "/sbin/pfctl -e -f /dev/stdin <<< 'block drop from \(ip) to any'")
        
        DispatchQueue.main.async {
            if result.success {
                self.statusMessage = "Blocked IP: \(ip)"
                self.saveFirewallRules()
            } else {
                self.statusMessage = "Failed to block IP: \(ip)"
            }
        }
    }
    
    func unblockIP(_ ip: String) {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.statusMessage = "Authorization required to unblock IPs"
            }
            return
        }
        
        blockedIPs.remove(ip)
        
        // Remove from pfctl
        let result = authService.executeWithAdminPrompt(command: "/sbin/pfctl -e -f /dev/stdin <<< 'pass from \(ip) to any'")
        
        DispatchQueue.main.async {
            if result.success {
                self.statusMessage = "Unblocked IP: \(ip)"
                self.saveFirewallRules()
            } else {
                self.statusMessage = "Failed to unblock IP: \(ip)"
            }
        }
    }
    
    private func blockConnection(_ connection: NetworkConnection) {
        let blocked = BlockedConnection(
            connection: connection,
            reason: "Suspicious activity detected",
            blockedAt: Date()
        )
        
        DispatchQueue.main.async {
            self.blockedConnections.append(blocked)
            self.statusMessage = "⚠️ Blocked connection from \(connection.processName)"
        }
        
        // Add to block list
        blockIP(connection.remoteAddress)
    }
    
    // MARK: - Persistence
    
    private func loadFirewallRules() {
        let path = NSHomeDirectory() + "/Library/Application Support/LibertyAccessControl/firewall_rules.json"
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let rules = try? JSONDecoder().decode([String: FirewallRule].self, from: data) else {
            return
        }
        
        applicationRules = rules
    }
    
    private func saveFirewallRules() {
        let path = NSHomeDirectory() + "/Library/Application Support/LibertyAccessControl/firewall_rules.json"
        
        do {
            let dirPath = (path as NSString).deletingLastPathComponent
            try fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            
            let data = try JSONEncoder().encode(applicationRules)
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            print("Failed to save firewall rules: \(error)")
        }
    }
    
    func clearBlockedConnections() {
        blockedConnections.removeAll()
    }
}

// MARK: - Models

struct NetworkConnection: Identifiable {
    let id: UUID
    let processName: String
    let processID: Int
    let bundleID: String?
    let `protocol`: String
    let localAddress: String
    let localPort: UInt16
    let remoteAddress: String
    let remotePort: UInt16
    let state: String
    let direction: ConnectionDirection
    let timestamp: Date
}

enum ConnectionDirection: String, Codable {
    case inbound = "Inbound"
    case outbound = "Outbound"
}

struct BlockedConnection: Identifiable {
    let id = UUID()
    let connection: NetworkConnection
    let reason: String
    let blockedAt: Date
}

struct FirewallRule: Codable {
    let bundleID: String
    let allowed: Bool
}
