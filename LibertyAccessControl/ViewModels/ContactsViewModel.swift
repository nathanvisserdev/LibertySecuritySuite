//
//  ContactsViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class ContactsViewModel: ObservableObject {
    @Published var statusMessage: String = "Contacts permissions management"
}
