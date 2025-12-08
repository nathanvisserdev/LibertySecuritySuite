//
//  CalReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import EventKit

class CalReqServ {
    func reqCalPerm() async throws -> (granted: Bool, message: String) {
        let eventStore = EKEventStore()
        
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                let message = granted ? "Calendar permission granted" : "Calendar permission denied"
                return (granted, message)
            } catch {
                return (false, "Calendar permission error: \(error.localizedDescription)")
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(returning: (false, "Calendar permission error: \(error.localizedDescription)"))
                        return
                    }
                    let message = granted ? "Calendar permission granted" : "Calendar permission denied"
                    continuation.resume(returning: (granted, message))
                }
            }
        }
    }
}
