//
//  RemReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import EventKit

class RemReqServ {
    func reqPerm() async throws -> (granted: Bool, message: String) {
        let eventStore = EKEventStore()
        
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToReminders()
                let message = granted ? "Reminders permission granted" : "Reminders permission denied"
                return (granted, message)
            } catch {
                return (false, "Reminders permission error: \(error.localizedDescription)")
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(returning: (false, "Reminders permission error: \(error.localizedDescription)"))
                        return
                    }
                    let message = granted ? "Reminders permission granted" : "Reminders permission denied"
                    continuation.resume(returning: (granted, message))
                }
            }
        }
    }
}
