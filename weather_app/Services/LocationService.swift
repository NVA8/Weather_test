//
//  LocationService.swift
//  weather_app
//
//  Created by Valeriy Nikitin on 2023-10-08.
//

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject {
    enum AuthorizationState {
        case notDetermined
        case allowed
        case denied
    }
    
    @Published private(set) var state: AuthorizationState = .notDetermined
    @Published private(set) var lastKnownLocation: CLLocationCoordinate2D?
    
    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            state = .denied
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            state = .allowed
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func refreshLocation() {
        guard state == .allowed else { return }
        manager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            state = .notDetermined
        case .restricted, .denied:
            state = .denied
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            state = .allowed
            manager.requestLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
