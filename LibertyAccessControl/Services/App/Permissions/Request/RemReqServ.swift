//
//  RemReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import EventKit

class RemReqServ {
    func reqPerm() async throws -> EKAuthorizationStatus {
        let eventStore = EKEventStore()
        
        if #available(macOS 14.0, *) {
            _ = try await eventStore.requestFullAccessToReminders()
            return EKEventStore.authorizationStatus(for: .reminder)
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { _, _ in
                    let status = EKEventStore.authorizationStatus(for: .reminder)
                    continuation.resume(returning: status)
                }
            }
        }
    }
}
