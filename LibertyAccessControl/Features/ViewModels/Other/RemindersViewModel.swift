//
//  RemindersViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import EventKit

struct RemindersApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class RemindersViewModel: ObservableObject {
    @Published var statusMessage: String = "Reminders access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var applications: [RemindersApp] = []
    
    private let eventStore = EKEventStore()
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        eventStore.requestFullAccessToReminders { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Reminders access granted"
                } else {
                    self?.statusMessage = "Reminders access denied"
                    self?.errorMessage = error?.localizedDescription ?? "User denied reminders access"
                }
            }
        }
    }
    
    func toggleAppAccess(for app: RemindersApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) reminders access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Reminders access not requested"
        case .restricted:
            statusMessage = "Reminders access restricted"
        case .denied:
            statusMessage = "Reminders access denied"
        case .fullAccess, .authorized:
            statusMessage = "Reminders access granted"
        case .writeOnly:
            statusMessage = "Reminders write-only access granted"
        @unknown default:
            statusMessage = "Unknown reminders authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            RemindersApp(name: "Reminders", bundleId: "com.apple.reminders", hasAccess: true),
            RemindersApp(name: "Calendar", bundleId: "com.apple.iCal", hasAccess: true),
            RemindersApp(name: "Mail", bundleId: "com.apple.mail", hasAccess: false),
            RemindersApp(name: "Notes", bundleId: "com.apple.Notes", hasAccess: false),
        ]
    }
}
