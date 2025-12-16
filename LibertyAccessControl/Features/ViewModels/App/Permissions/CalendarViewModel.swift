//
//  CalendarViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import EventKit

struct CalendarApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class CalendarViewModel: ObservableObject {
    @Published var statusMessage: String = "Calendar access not requested"
    @Published var errorMessage: String?
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var applications: [CalendarApp] = []
    
    private let eventStore = EKEventStore()
    
    init() {
        updateAuthorizationStatus()
        loadApplications()
    }
    
    func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
                if granted {
                    self?.statusMessage = "Calendar access granted"
                } else {
                    self?.statusMessage = "Calendar access denied"
                    self?.errorMessage = error?.localizedDescription ?? "User denied calendar access"
                }
            }
        }
    }
    
    func toggleAppAccess(for app: CalendarApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) calendar access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Calendar access not requested"
        case .restricted:
            statusMessage = "Calendar access restricted"
        case .denied:
            statusMessage = "Calendar access denied"
        case .fullAccess, .authorized:
            statusMessage = "Calendar access granted"
        case .writeOnly:
            statusMessage = "Calendar write-only access granted"
        @unknown default:
            statusMessage = "Unknown calendar authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            CalendarApp(name: "Mail", bundleId: "com.apple.mail", hasAccess: true),
            CalendarApp(name: "Reminders", bundleId: "com.apple.reminders", hasAccess: true),
            CalendarApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            CalendarApp(name: "Contacts", bundleId: "com.apple.AddressBook", hasAccess: false),
        ]
    }
}
