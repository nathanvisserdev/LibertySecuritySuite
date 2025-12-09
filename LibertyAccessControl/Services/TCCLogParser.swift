//
//  TCCLogParser.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation

class TCCLogParser {
    
    func parseLogLine(_ line: String) -> TCCAccessRequest? {
        guard !line.isEmpty else { return nil }
        
        // Check if this is a TCC-related log line
        guard line.contains("TCCAccessRequest") ||
              line.contains("kTCCService") ||
              line.contains("access") else {
            return nil
        }
        
        let processName = extractProcessName(from: line)
        let serviceName = extractServiceName(from: line)
        let decision = extractDecision(from: line)
        
        return TCCAccessRequest(
            timestamp: Date(),
            processName: processName,
            serviceName: serviceName,
            decision: decision,
            rawLogLine: line
        )
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
        // Extract TCC service name with kTCCService prefix
        if let range = line.range(of: #"kTCCService[A-Za-z]+"#, options: .regularExpression) {
            let service = String(line[range])
            let rawName = service.replacingOccurrences(of: "kTCCService", with: "")
            return mapServiceName(rawName)
        }
        
        // Fallback: check for service keywords
        if line.contains("Camera") { return "Camera" }
        if line.contains("Microphone") { return "Microphone" }
        if line.contains("ScreenCapture") || line.contains("screen") { return "Screen Recording" }
        if line.contains("SystemPolicyAllFiles") || line.contains("AllFiles") { return "Full Disk Access" }
        if line.contains("Location") { return "Location Services" }
        if line.contains("Contacts") { return "Contacts" }
        if line.contains("Calendar") { return "Calendar" }
        if line.contains("Photos") || line.contains("PhotoLibrary") { return "Photos" }
        if line.contains("Accessibility") { return "Accessibility" }
        if line.contains("Bluetooth") { return "Bluetooth" }
        if line.contains("Reminders") { return "Reminders" }
        if line.contains("AppleEvents") { return "Apple Events" }
        if line.contains("SpeechRecognition") { return "Speech Recognition" }
        
        return "Unknown Service"
    }
    
    private func mapServiceName(_ rawName: String) -> String {
        // Map kTCCService names to readable names
        let serviceMap: [String: String] = [
            "Camera": "Camera",
            "Microphone": "Microphone",
            "ScreenCapture": "Screen Recording",
            "ListenEvent": "Input Monitoring",
            "PostEvent": "Keyboard Access",
            "SystemPolicyAllFiles": "Full Disk Access",
            "SystemPolicySysAdminFiles": "System Admin Files",
            "SystemPolicyDesktopFolder": "Desktop Folder",
            "SystemPolicyDocumentsFolder": "Documents Folder",
            "SystemPolicyDownloadsFolder": "Downloads Folder",
            "SystemPolicyNetworkVolumes": "Network Volumes",
            "SystemPolicyRemovableVolumes": "Removable Volumes",
            "Location": "Location Services",
            "Contacts": "Contacts",
            "Calendar": "Calendar",
            "Reminders": "Reminders",
            "Photos": "Photos",
            "PhotosAdd": "Photos (Add Only)",
            "MediaLibrary": "Apple Music",
            "Accessibility": "Accessibility",
            "AddressBook": "Contacts",
            "AppleEvents": "Apple Events",
            "Bluetooth": "Bluetooth",
            "BluetoothAlways": "Bluetooth (Always)",
            "FileProviderPresence": "File Provider Presence",
            "Motion": "Motion & Fitness",
            "SpeechRecognition": "Speech Recognition",
            "Siri": "Siri",
            "Liverpool": "Home",
            "Ubiquity": "iCloud",
            "Willow": "HomeKit",
            "ShareKit": "Share Menu",
            "UserTracking": "User Tracking"
        ]
        
        return serviceMap[rawName] ?? rawName
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
}
