//
//  ContReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Contacts

class ContReqServ {
    func reqContPerm() async throws -> (granted: Bool, message: String) {
        let store = CNContactStore()
        
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    continuation.resume(returning: (false, "Contacts permission error: \(error.localizedDescription)"))
                    return
                }
                let message = granted ? "Contacts permission granted" : "Contacts permission denied"
                continuation.resume(returning: (granted, message))
            }
        }
    }
}
