//
//  NotReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import UserNotifications

class NotReqServ {
    func reqNotPerm() async throws -> (granted: Bool, message: String) {
        return try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let message = granted ? "Notification permission granted" : "Notification permission denied"
                continuation.resume(returning: (granted, message))
            }
        }
    }
}
