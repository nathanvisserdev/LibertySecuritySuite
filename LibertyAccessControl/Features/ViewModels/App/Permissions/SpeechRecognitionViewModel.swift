//
//  SpeechRecognitionViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Speech

struct SpeechApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class SpeechRecognitionViewModel: ObservableObject {
    @Published var statusMessage: String = "Speech recognition access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var applications: [SpeechApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                switch status {
                case .authorized:
                    self?.statusMessage = "Speech recognition access granted"
                case .denied:
                    self?.statusMessage = "Speech recognition access denied"
                    self?.errorMessage = "User denied speech recognition access"
                case .restricted:
                    self?.statusMessage = "Speech recognition access restricted"
                    self?.errorMessage = "Speech recognition is restricted"
                default:
                    break
                }
            }
        }
    }
    
    func toggleAppAccess(for app: SpeechApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) speech recognition access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Speech recognition access not requested"
        case .restricted:
            statusMessage = "Speech recognition access restricted"
        case .denied:
            statusMessage = "Speech recognition access denied"
        case .authorized:
            statusMessage = "Speech recognition access granted"
        @unknown default:
            statusMessage = "Unknown speech recognition authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            SpeechApp(name: "Dictation", bundleId: "com.apple.speech.synthesisserver", hasAccess: true),
            SpeechApp(name: "Siri", bundleId: "com.apple.assistant", hasAccess: true),
            SpeechApp(name: "Notes", bundleId: "com.apple.Notes", hasAccess: false),
            SpeechApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
        ]
    }
}
