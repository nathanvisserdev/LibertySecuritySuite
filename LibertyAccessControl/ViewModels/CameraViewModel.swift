//
//  CameraViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import AVFoundation

struct CameraApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class CameraViewModel: ObservableObject {
    @Published var statusMessage: String = "Camera access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var applications: [CameraApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Camera access granted"
                } else {
                    self?.statusMessage = "Camera access denied"
                    self?.errorMessage = "User denied camera access"
                }
            }
        }
    }
    
    func toggleAppAccess(for app: CameraApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) camera access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Camera access not requested"
        case .restricted:
            statusMessage = "Camera access restricted"
        case .denied:
            statusMessage = "Camera access denied"
        case .authorized:
            statusMessage = "Camera access granted"
        @unknown default:
            statusMessage = "Unknown camera authorization status"
        }
    }
    
    private func loadApplications() {
        // Mock data - in reality would read from TCC database
        applications = [
            CameraApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            CameraApp(name: "Chrome", bundleId: "com.google.Chrome", hasAccess: true),
            CameraApp(name: "Zoom", bundleId: "us.zoom.xos", hasAccess: true),
            CameraApp(name: "FaceTime", bundleId: "com.apple.FaceTime", hasAccess: true),
        ]
    }
}
