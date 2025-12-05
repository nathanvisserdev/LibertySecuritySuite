//
//  BluetoothViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine

class BluetoothViewModel: ObservableObject {
    @Published var statusMessage: String = "Bluetooth permissions management"
}
