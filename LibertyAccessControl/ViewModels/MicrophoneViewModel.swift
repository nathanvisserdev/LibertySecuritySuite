//
//  MicrophoneViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import AVFoundation

struct MicrophoneApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class MicrophoneViewModel: ObservableObject {
    @Published var statusMessage: String = "Microphone access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var applications: [MicrophoneApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Microphone access granted"
                } else {
                    self?.statusMessage = "Microphone access denied"
                    self?.errorMessage = "User denied microphone access"
                }
            }
        }
    }
    
    func allowAccess() {
        // This would require system-level permissions to modify TCC database
        // For demonstration, we'll show what would happen
        statusMessage = "Allowing microphone access requires system privileges"
        errorMessage = "This requires modifying the TCC database at /Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    func denyAccess() {
        // This would require system-level permissions to modify TCC database
        statusMessage = "Denying microphone access requires system privileges"
        errorMessage = "This requires modifying the TCC database at /Library/Application Support/com.apple.TCC/TCC.db"
    }
    
    func toggleAppAccess(for app: MicrophoneApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        
        // In a real implementation, this would modify the TCC database
        // using direct SQL queries with proper permissions
        statusMessage = "\(app.name) microphone access \(applications[index].hasAccess ? "granted" : "denied")"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch authorizationStatus {
        case .authorized:
            statusMessage = "Microphone access authorized"
        case .denied:
            statusMessage = "Microphone access denied"
        case .restricted:
            statusMessage = "Microphone access restricted"
        case .notDetermined:
            statusMessage = "Microphone access not requested"
        @unknown default:
            statusMessage = "Unknown authorization status"
        }
    }
    
    private func loadApplications() {
        // Load common applications that might request microphone access
        // In a real implementation, you'd query the TCC database
        applications = [
            MicrophoneApp(name: "Zoom", bundleId: "us.zoom.xos", hasAccess: false),
            MicrophoneApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            MicrophoneApp(name: "Chrome", bundleId: "com.google.Chrome", hasAccess: false),
            MicrophoneApp(name: "Discord", bundleId: "com.hnc.Discord", hasAccess: false),
            MicrophoneApp(name: "Slack", bundleId: "com.tinyspeck.slackmacgap", hasAccess: false),
            MicrophoneApp(name: "Microsoft Teams", bundleId: "com.microsoft.teams", hasAccess: false),
            MicrophoneApp(name: "Skype", bundleId: "com.skype.skype", hasAccess: false),
            MicrophoneApp(name: "FaceTime", bundleId: "com.apple.FaceTime", hasAccess: false),
            MicrophoneApp(name: "Voice Memos", bundleId: "com.apple.VoiceMemos", hasAccess: false),
            MicrophoneApp(name: "QuickTime Player", bundleId: "com.apple.QuickTimePlayerX", hasAccess: false)
        ]
    }
}
