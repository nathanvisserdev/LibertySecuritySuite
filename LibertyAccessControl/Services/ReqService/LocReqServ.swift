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
    private var continuation: CheckedContinuation<(granted: Bool, message: String), Error>?
    
    func reqLocPerm() async throws -> (granted: Bool, message: String) {
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
        case .authorizedWhenInUse, .authorizedAlways:
            continuation?.resume(returning: (true, "Location permission granted"))
        case .denied, .restricted:
            continuation?.resume(returning: (false, "Location permission denied"))
        case .notDetermined:
            return // Wait for user decision
        @unknown default:
            continuation?.resume(returning: (false, "Unknown location permission status"))
        }
        
        continuation = nil
    }
}
