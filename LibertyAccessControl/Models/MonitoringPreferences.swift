//
//  MonitoringPreferences.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Combine

class MonitoringPreferences: ObservableObject {
    @Published var monitoredServices: Set<TCCServiceType> = []
    @Published var trustedApps: Set<String> = [] // Bundle IDs
    @Published var notifyOnlyDenied: Bool = true
    @Published var notifyHighPriorityOnly: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let monitoredServicesKey = "monitoredServices"
    private let trustedAppsKey = "trustedApps"
    private let notifyOnlyDeniedKey = "notifyOnlyDenied"
    private let notifyHighPriorityKey = "notifyHighPriority"
    
    init() {
        loadPreferences()
        
        // Set default high-priority services if empty
        if monitoredServices.isEmpty {
            monitoredServices = [
                .camera,
                .microphone,
                .screenRecording,
                .fullDiskAccess,
                .bluetooth,
                .accessibility,
                .keyboardAccess
            ]
        }
        
        // Auto-trust Apple and system apps by default
        if trustedApps.isEmpty {
            trustedApps = getDefaultTrustedApps()
        }
    }
    
    func savePreferences() {
        userDefaults.set(Array(monitoredServices.map { $0.rawValue }), forKey: monitoredServicesKey)
        userDefaults.set(Array(trustedApps), forKey: trustedAppsKey)
        userDefaults.set(notifyOnlyDenied, forKey: notifyOnlyDeniedKey)
        userDefaults.set(notifyHighPriorityOnly, forKey: notifyHighPriorityKey)
    }
    
    private func loadPreferences() {
        if let savedServices = userDefaults.array(forKey: monitoredServicesKey) as? [String] {
            monitoredServices = Set(savedServices.compactMap { TCCServiceType(rawValue: $0) })
        }
        
        if let savedApps = userDefaults.array(forKey: trustedAppsKey) as? [String] {
            trustedApps = Set(savedApps)
        }
        
        notifyOnlyDenied = userDefaults.bool(forKey: notifyOnlyDeniedKey)
        notifyHighPriorityOnly = userDefaults.bool(forKey: notifyHighPriorityKey)
    }
    
    func addTrustedApp(_ bundleId: String) {
        trustedApps.insert(bundleId)
        savePreferences()
    }
    
    func removeTrustedApp(_ bundleId: String) {
        trustedApps.remove(bundleId)
        savePreferences()
    }
    
    func isAppTrusted(_ bundleId: String) -> Bool {
        return trustedApps.contains(bundleId)
    }
    
    func shouldNotify(for request: TCCAccessRequest) -> Bool {
        // Check if denied only filter is enabled
        if notifyOnlyDenied && !request.decision.contains("✗") {
            return false
        }
        
        // Check if service is in monitored list
        let serviceType = TCCServiceType.from(serviceName: request.serviceName)
        if !monitoredServices.contains(serviceType) {
            return false
        }
        
        // Check if app is trusted (would need to extract bundle ID from processName)
        // This is simplified - you'd need better process -> bundle ID mapping
        
        return true
    }
    
    private func getDefaultTrustedApps() -> Set<String> {
        return Set([
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.systempreferences",
            "com.apple.systemsettings",
            "com.apple.Terminal",
            "com.apple.loginwindow",
            "com.apple.WindowServer",
            "com.apple.CoreServices.SystemUIServer"
        ])
    }
}

enum TCCServiceType: String, CaseIterable, Identifiable {
    case camera = "Camera"
    case microphone = "Microphone"
    case screenRecording = "Screen Recording"
    case fullDiskAccess = "Full Disk Access"
    case bluetooth = "Bluetooth"
    case accessibility = "Accessibility"
    case keyboardAccess = "Keyboard Access"
    case location = "Location Services"
    case contacts = "Contacts"
    case calendar = "Calendar"
    case photos = "Photos"
    case reminders = "Reminders"
    case filesAndFolders = "Files and Folders"
    case appleEvents = "Apple Events"
    case speechRecognition = "Speech Recognition"
    
    var id: String { rawValue }
    
    var isHighPriority: Bool {
        switch self {
        case .camera, .microphone, .screenRecording, .fullDiskAccess, .bluetooth, .accessibility, .keyboardAccess:
            return true
        default:
            return false
        }
    }
    
    static func from(serviceName: String) -> TCCServiceType {
        let normalized = serviceName.lowercased()
        
        if normalized.contains("camera") { return .camera }
        if normalized.contains("microphone") { return .microphone }
        if normalized.contains("screen") || normalized.contains("capture") { return .screenRecording }
        if normalized.contains("disk") || normalized.contains("allfiles") { return .fullDiskAccess }
        if normalized.contains("bluetooth") { return .bluetooth }
        if normalized.contains("accessibility") { return .accessibility }
        if normalized.contains("keyboard") || normalized.contains("postevent") || normalized.contains("input monitoring") { return .keyboardAccess }
        if normalized.contains("location") { return .location }
        if normalized.contains("contacts") || normalized.contains("addressbook") { return .contacts }
        if normalized.contains("calendar") { return .calendar }
        if normalized.contains("photos") { return .photos }
        if normalized.contains("reminders") { return .reminders }
        if normalized.contains("folder") || normalized.contains("desktop") || normalized.contains("documents") || normalized.contains("downloads") { return .filesAndFolders }
        if normalized.contains("apple") && normalized.contains("events") { return .appleEvents }
        if normalized.contains("speech") { return .speechRecognition }
        
        return .fullDiskAccess // Default to high priority if unknown
    }
}
