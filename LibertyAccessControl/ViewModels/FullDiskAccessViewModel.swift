//
//  FullDiskAccessViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class FullDiskAccessViewModel: ObservableObject {
    @Published var statusMessage: String = "Full Disk Access permissions management"
}
