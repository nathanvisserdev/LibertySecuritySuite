//
//  NotificationService.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import UserNotifications

class NotificationService {
    private let preferences: MonitoringPreferences
    private let trustManager: AppTrustManager
    
    init(preferences: MonitoringPreferences, trustManager: AppTrustManager) {
        self.preferences = preferences
        self.trustManager = trustManager
    }
    
    func requestPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendNotification(for request: TCCAccessRequest) {
        // Check if we should notify based on user preferences
        guard preferences.shouldNotify(for: request) else {
            return
        }
        
        // Check if app is trusted
        let bundleId = trustManager.getBundleId(from: request.processName)
        guard !trustManager.isAppTrusted(processName: request.processName, bundleId: bundleId) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "TCC Access Request"
        content.body = "\(request.processName) requested \(request.serviceName)"
        content.subtitle = request.decision
        content.sound = .default
        
        // Color-code the notification based on decision
        if request.decision.contains("✗") {
            content.categoryIdentifier = "TCC_DENIED"
        } else if request.decision.contains("✓") {
            content.categoryIdentifier = "TCC_ALLOWED"
        } else {
            content.categoryIdentifier = "TCC_PROMPT"
        }
        
        let notificationRequest = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(notificationRequest) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}
