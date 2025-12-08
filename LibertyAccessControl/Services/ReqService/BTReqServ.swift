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
    private var continuation: CheckedContinuation<Bool, Never>?
    
    func reqPerm() async -> Bool {
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
            continuation.resume(returning: true)
        case .unauthorized:
            continuation.resume(returning: false)
        case .poweredOff:
            continuation.resume(returning: false)
        case .unsupported:
            continuation.resume(returning: false)
        case .unknown, .resetting:
            return // Wait for final state
        @unknown default:
            continuation.resume(returning: false)
        }
        
        self.continuation = nil
    }
}
