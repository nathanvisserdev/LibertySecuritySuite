//
//  LocationViewModel.swift
//  LibertyAccessControl
//
//  Created by Nathan Visser on 2025-12-05.
//

import Foundation
import Combine
import CoreLocation

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isLocationEnabled: Bool = false
    @Published var statusMessage: String = "Location services not enabled"
    @Published var errorMessage: String?
    @Published var currentLocation: String = "No location data"
    
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    func requestLocation() {
        guard let manager = locationManager else { return }
        
        // Request authorization
        manager.requestWhenInUseAuthorization()
        
        // Request a single location update
        manager.requestLocation()
        
        statusMessage = "Requesting location..."
    }
    
    func enableLocation() {
        guard let manager = locationManager else { return }
        
        isLocationEnabled = true
        statusMessage = "Location services enabled"
        errorMessage = nil
        
        // Start continuous location updates
        manager.startUpdatingLocation()
    }
    
    func disableLocation() {
        locationManager?.stopUpdatingLocation()
        isLocationEnabled = false
        statusMessage = "Location services disabled"
        errorMessage = nil
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = String(format: "%.6f, %.6f", latitude, longitude)
            self?.statusMessage = "Location received"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Failed to get location: \(error.localizedDescription)"
            self?.statusMessage = "Location request failed"
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                self?.statusMessage = "Location authorization granted"
            case .denied:
                self?.errorMessage = "Location access denied"
                self?.statusMessage = "Please enable location in System Settings"
            case .restricted:
                self?.errorMessage = "Location access restricted"
            case .notDetermined:
                self?.statusMessage = "Location authorization not determined"
            @unknown default:
                break
            }
        }
    }
}
