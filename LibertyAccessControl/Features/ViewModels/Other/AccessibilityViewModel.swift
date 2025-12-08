//
//  AccessibilityViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import ApplicationServices

struct AccessibilityApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class AccessibilityViewModel: ObservableObject {
    @Published var statusMessage: String = "Accessibility access not granted"
    @Published var errorMessage: String?
    @Published var applications: [AccessibilityApp] = []
    @Published var hasAccess: Bool = false
    
    init() {
        loadApplications()
        checkAccess()
    }
    
    func requestAccess() {
        // Check if we have accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        hasAccess = accessEnabled
        
        if accessEnabled {
            statusMessage = "Accessibility access granted"
            errorMessage = nil
        } else {
            statusMessage = "Accessibility access denied"
            errorMessage = "Please enable Accessibility access in System Settings > Privacy & Security > Accessibility"
        }
    }
    
    func toggleAppAccess(for app: AccessibilityApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) accessibility access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func checkAccess() {
        hasAccess = AXIsProcessTrusted()
        
        if hasAccess {
            statusMessage = "Accessibility access granted"
        } else {
            statusMessage = "Accessibility access not granted - Click 'Request Access' to enable"
        }
    }
    
    private func loadApplications() {
        applications = [
            AccessibilityApp(name: "Alfred", bundleId: "com.runningwithcrayons.Alfred", hasAccess: true),
            AccessibilityApp(name: "BetterTouchTool", bundleId: "com.hegenberg.BetterTouchTool", hasAccess: true),
            AccessibilityApp(name: "Keyboard Maestro", bundleId: "com.stairways.keyboardmaestro.engine", hasAccess: true),
            AccessibilityApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
        ]
    }
}
