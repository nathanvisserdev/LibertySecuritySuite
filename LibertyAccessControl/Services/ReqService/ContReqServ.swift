//
//  ContReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import Contacts

class ContReqServ {
    func reqPerm() async throws -> CNAuthorizationStatus {
        let store = CNContactStore()
        
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { _, _ in
                let status = CNContactStore.authorizationStatus(for: .contacts)
                continuation.resume(returning: status)
            }
        }
    }
}
