//
//  LocReqServ.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-08.
//

import Foundation
import CoreLocation

class LocReqServ: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var continuation: CheckedContinuation<CLAuthorizationStatus, Error>?
    
    func reqPerm() async throws -> CLAuthorizationStatus {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            DispatchQueue.main.async {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                self.locationManager?.requestWhenInUseAuthorization()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        guard continuation != nil else { return }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways, .denied, .restricted:
            continuation?.resume(returning: status)
            continuation = nil
        case .notDetermined:
            return // Wait for user decision
        @unknown default:
            continuation?.resume(returning: status)
            continuation = nil
        }
    }
}
