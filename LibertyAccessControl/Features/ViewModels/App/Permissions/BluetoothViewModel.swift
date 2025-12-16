//
//  BluetoothViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import CoreBluetooth

struct BluetoothApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    var hasAccess: Bool
}

class BluetoothViewModel: NSObject, ObservableObject {
    @Published var statusMessage: String = "Bluetooth access not requested"
    @Published var errorMessage: String?
    @Published var applications: [BluetoothApp] = []
    
    private var centralManager: CBCentralManager?
    private var authorizationStatus: CBManagerAuthorization = .notDetermined
    
    override init() {
        super.init()
        loadApplications()
        updateAuthorizationStatus()
    }
    
    func requestAccess() {
        // Initialize CBCentralManager which will trigger permission prompt
        centralManager = CBCentralManager(delegate: self, queue: nil)
        statusMessage = "Requesting Bluetooth access..."
    }
    
    func toggleAppAccess(for app: BluetoothApp) {
        guard let index = applications.firstIndex(where: { $0.id == app.id }) else { return }
        
        applications[index].hasAccess.toggle()
        statusMessage = "\(app.name) bluetooth access \(applications[index].hasAccess ? "granted" : "denied")"
        errorMessage = "Modifying app permissions requires system privileges and TCC database access"
    }
    
    private func updateAuthorizationStatus() {
        authorizationStatus = CBCentralManager.authorization
        
        switch authorizationStatus {
        case .notDetermined:
            statusMessage = "Bluetooth access not requested"
        case .restricted:
            statusMessage = "Bluetooth access restricted"
        case .denied:
            statusMessage = "Bluetooth access denied"
        case .allowedAlways:
            statusMessage = "Bluetooth access granted"
        @unknown default:
            statusMessage = "Unknown bluetooth authorization status"
        }
    }
    
    private func loadApplications() {
        applications = [
            BluetoothApp(name: "System Settings", bundleId: "com.apple.systempreferences", hasAccess: true),
            BluetoothApp(name: "Bluetooth File Exchange", bundleId: "com.apple.BluetoothFileExchange", hasAccess: true),
            BluetoothApp(name: "Safari", bundleId: "com.apple.Safari", hasAccess: false),
            BluetoothApp(name: "Chrome", bundleId: "com.google.Chrome", hasAccess: false),
        ]
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAuthorizationStatus()
        }
    }
}
