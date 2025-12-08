//
//  PhotosViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Photos

struct PhotosApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class PhotosViewModel: ObservableObject {
    @Published var statusMessage: String = "Photos access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var applications: [PhotosApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                switch status {
                case .authorized, .limited:
                    self?.statusMessage = "Photos access granted"
                case .denied:
                    self?.statusMessage = "Photos access denied"
                    self?.errorMessage = "User denied photos access"
                case .restricted:
                    self?.statusMessage = "Photos access restricted"
                    self?.errorMessage = "Photos access is restricted"
                default:
                    break
                }
            }
        }
    }
    
    func toggleAppAccess(for app: PhotosApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) photos access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Photos access not requested"
        case .restricted:
            statusMessage = "Photos access restricted"
        case .denied:
            statusMessage = "Photos access denied"
        case .authorized:
            statusMessage = "Photos access granted"
        case .limited:
            statusMessage = "Limited photos access granted"
        @unknown default:
            statusMessage = "Unknown photos authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            PhotosApp(name: "Photos", bundleId: "com.apple.Photos", hasAccess: true),
            PhotosApp(name: "Preview", bundleId: "com.apple.Preview", hasAccess: true),
            PhotosApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            PhotosApp(name: "Chrome", bundleId: "com.google.Chrome", hasAccess: false),
        ]
    }
}
