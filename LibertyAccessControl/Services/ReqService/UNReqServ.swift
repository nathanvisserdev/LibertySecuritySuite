//
//  UNReq.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import UserNotifications

class UNReq {
    func reqPerm() async throws -> UNAuthorizationStatus {
        return try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // After requesting, get the actual authorization status
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    continuation.resume(returning: settings.authorizationStatus)
                }
            }
        }
    }
}
