//
//  LocationService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var errorMessage: String?

    // Default to Paris (MyBookClub HQ / seed city) if location unavailable
    var coordinate: CLLocationCoordinate2D {
        currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35)
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced  // iOS 14+ city-level
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - GDPR: round coordinates to 2 decimal places (~1km precision)

    var roundedLatitude: Double {
        (coordinate.latitude * 100).rounded() / 100
    }

    var roundedLongitude: Double {
        (coordinate.longitude * 100).rounded() / 100
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        manager.stopUpdatingLocation()  // one-shot for discovery; re-request on tab open
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location unavailable. Showing clubs in the default city."
    }
}
