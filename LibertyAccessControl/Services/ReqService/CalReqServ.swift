//
//  CalReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import EventKit

class CalReqServ {
    func reqPerm() async throws -> EKAuthorizationStatus {
        let eventStore = EKEventStore()
        
        if #available(macOS 14.0, *) {
            _ = try await eventStore.requestFullAccessToEvents()
            return EKEventStore.authorizationStatus(for: .event)
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { _, _ in
                    let status = EKEventStore.authorizationStatus(for: .event)
                    continuation.resume(returning: status)
                }
            }
        }
    }
}
