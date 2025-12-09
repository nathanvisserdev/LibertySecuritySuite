//
//  ReqMonVM.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class ReqMonVM: ObservableObject {
    @Published private(set) var isNotificationsEnabled: Bool = false
    @Published var statusMessage: String = "Monitoring initializing..."
    @Published var errorMessage: String?
    @Published private(set) var accessRequests: [TCCAccessRequest] = []
    
    private let monitorService: SystemMonitorService
    private let notificationService: NotificationService
    
    init(monitorService: SystemMonitorService, notificationService: NotificationService) {
        self.monitorService = monitorService
        self.notificationService = notificationService
        
        setupCallbacks()
    }
    
    func startBackgroundMonitoring() {
        notificationService.requestPermissions()
        monitorService.startMonitoring()
        isNotificationsEnabled = true
    }
    
    private func setupCallbacks() {
        monitorService.onRequestReceived = { [weak self] request in
            self?.accessRequests.insert(request, at: 0)
            
            // Keep only last 100 entries
            if let count = self?.accessRequests.count, count > 100 {
                self?.accessRequests.removeLast()
            }
        }
        
        monitorService.onStatusChange = { [weak self] status in
            self?.statusMessage = status
        }
        
        monitorService.onError = { [weak self] error in
            self?.errorMessage = error
            self?.isNotificationsEnabled = false
        }
    }
}
