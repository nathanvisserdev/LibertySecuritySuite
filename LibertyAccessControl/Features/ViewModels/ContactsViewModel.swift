//
//  ContactsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import Contacts

struct ContactsApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class ContactsViewModel: ObservableObject {
    @Published var statusMessage: String = "Contacts access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var applications: [ContactsApp] = []
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Contacts access granted"
                } else {
                    self?.statusMessage = "Contacts access denied"
                    self?.errorMessage = error?.localizedDescription ?? "User denied contacts access"
                }
            }
        }
    }
    
    func toggleAppAccess(for app: ContactsApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) contacts access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Contacts access not requested"
        case .restricted:
            statusMessage = "Contacts access restricted"
        case .denied:
            statusMessage = "Contacts access denied"
        case .authorized:
            statusMessage = "Contacts access granted"
        @unknown default:
            statusMessage = "Unknown contacts authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            ContactsApp(name: "Mail", bundleId: "com.apple.mail", hasAccess: true),
            ContactsApp(name: "Messages", bundleId: "com.apple.MobileSMS", hasAccess: true),
            ContactsApp(name: "FaceTime", bundleId: "com.apple.FaceTime", hasAccess: true),
            ContactsApp(name: "Calendar", bundleId: "com.apple.iCal", hasAccess: false),
        ]
    }
}
