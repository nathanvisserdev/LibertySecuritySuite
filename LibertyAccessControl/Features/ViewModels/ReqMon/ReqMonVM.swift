//
//  ReqMonVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Darwin
import UserNotifications

class ReqMonVM: ObservableObject {
    @Published var isNotificationsEnabled: Bool = false
    @Published var statusMessage: String = "Notifications not enabled"
    @Published var errorMessage: String?
    @Published var accessRequests: [TCCAccessRequest] = []
    
    private var monitoringQueue: DispatchQueue?
    private var isMonitoring: Bool = false
    private var logFileDescriptor: Int32 = -1
    
    func requestNotificationPermission() {
        requestNotificationPermissions()
    }
    
    func enableMonitoring() {
        // Start monitoring TCC daemon activity by tailing the system log
        isMonitoring = true
        isNotificationsEnabled = true
        statusMessage = "TCC monitoring enabled - watching for access requests"
        errorMessage = nil
        
        monitoringQueue = DispatchQueue(label: "com.libertyaccess.tcc", qos: .userInitiated)
        monitoringQueue?.async { [weak self] in
            self?.monitorTCCDaemon()
        }
    }
    
    func disableMonitoring() {
        isMonitoring = false
        isNotificationsEnabled = false
        statusMessage = "TCC monitoring disabled"
        errorMessage = nil
        
        if logFileDescriptor >= 0 {
            close(logFileDescriptor)
            logFileDescriptor = -1
        }
    }
    
    private func monitorTCCDaemon() {
        // Use 'log stream' command to monitor TCC daemon in real-time
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        task.arguments = [
            "stream",
            "--predicate", "subsystem == 'com.apple.TCC'",
            "--style", "compact"
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let handle = pipe.fileHandleForReading
            
            // Read output continuously
            while isMonitoring && task.isRunning {
                let data = handle.availableData
                
                guard !data.isEmpty else {
                    continue
                }
                
                if let output = String(data: data, encoding: .utf8) {
                    parseTCCLogOutput(output)
                }
            }
            
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to start TCC monitoring: \(error.localizedDescription)"
                self?.statusMessage = "TCC monitoring failed"
                self?.isNotificationsEnabled = false
            }
        }
    }
    
    private func parseTCCLogOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            // Parse TCC log entries
            // Format typically contains: timestamp, process, service, decision
            if line.contains("TCCAccessRequest") || 
               line.contains("kTCCService") ||
               line.contains("access") {
                
                let processName = extractProcessName(from: line)
                let serviceName = extractServiceName(from: line)
                let decision = extractDecision(from: line)
                
                let request = TCCAccessRequest(
                    timestamp: Date(),
                    processName: processName,
                    serviceName: serviceName,
                    decision: decision,
                    rawLogLine: line
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.accessRequests.insert(request, at: 0)
                    self?.statusMessage = "Latest: \(processName) requested \(serviceName)"
                    
                    // Send notification
                    self?.sendNotification(for: request)
                    
                    // Keep only last 100 entries
                    if let count = self?.accessRequests.count, count > 100 {
                        self?.accessRequests.removeLast()
                    }
                }
            }
        }
    }
    
    private func extractProcessName(from line: String) -> String {
        // Extract process name from log line
        if let range = line.range(of: #"process=([^\s,]+)"#, options: .regularExpression) {
            let match = String(line[range])
            return match.replacingOccurrences(of: "process=", with: "")
        }
        
        // Fallback: look for common patterns
        let components = line.components(separatedBy: " ")
        for (index, component) in components.enumerated() {
            if component.contains("tccd") && index + 1 < components.count {
                return components[index + 1]
            }
        }
        
        return "Unknown"
    }
    
    private func extractServiceName(from line: String) -> String {
        // Extract TCC service name
        if let range = line.range(of: #"kTCCService[A-Za-z]+"#, options: .regularExpression) {
            let service = String(line[range])
            return service.replacingOccurrences(of: "kTCCService", with: "")
        }
        
        // Common services
        if line.contains("Camera") { return "Camera" }
        if line.contains("Microphone") { return "Microphone" }
        if line.contains("ScreenCapture") { return "Screen Recording" }
        if line.contains("SystemPolicyAllFiles") { return "Full Disk Access" }
        if line.contains("Location") { return "Location Services" }
        if line.contains("Contacts") { return "Contacts" }
        if line.contains("Calendar") { return "Calendar" }
        if line.contains("Photos") { return "Photos" }
        
        return "Unknown Service"
    }
    
    private func extractDecision(from line: String) -> String {
        if line.contains("ALLOW") || line.contains("allowed") {
            return "✓ Allowed"
        } else if line.contains("DENY") || line.contains("denied") {
            return "✗ Denied"
        } else if line.contains("prompt") {
            return "? Prompting"
        }
        return "Checking"
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func sendNotification(for request: TCCAccessRequest) {
        let content = UNMutableNotificationContent()
        content.title = "TCC Access Request"
        content.body = "\(request.processName) requested \(request.serviceName)"
        content.subtitle = request.decision
        content.sound = .default
        
        // Color-code the notification based on decision
        if request.decision.contains("✗") {
            content.categoryIdentifier = "TCC_DENIED"
        } else if request.decision.contains("✓") {
            content.categoryIdentifier = "TCC_ALLOWED"
        } else {
            content.categoryIdentifier = "TCC_PROMPT"
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    deinit {
        disableMonitoring()
    }
}
