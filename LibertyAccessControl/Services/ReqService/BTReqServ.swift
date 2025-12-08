//
//  BTReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import CoreBluetooth
// TBD Return type
class BTReqServ: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var continuation: CheckedContinuation<(granted: Bool, message: String), Never>?
    
    func reqPerm() async -> (granted: Bool, message: String) {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            
            DispatchQueue.main.async {
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let continuation = self.continuation else { return }
        
        switch central.state {
        case .poweredOn:
            continuation.resume(returning: (true, "Bluetooth permission granted"))
        case .unauthorized:
            continuation.resume(returning: (false, "Bluetooth permission denied"))
        case .poweredOff:
            continuation.resume(returning: (false, "Bluetooth is powered off"))
        case .unsupported:
            continuation.resume(returning: (false, "Bluetooth is not supported on this device"))
        case .unknown, .resetting:
            return // Wait for final state
        @unknown default:
            continuation.resume(returning: (false, "Unknown Bluetooth state"))
        }
        
        self.continuation = nil
    }
}
