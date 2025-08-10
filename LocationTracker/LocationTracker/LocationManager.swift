import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var isTracking: Bool = false

    // To be used for saving data
    var didUpdateLocation: ((CLLocation) -> Void)?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() {
        self.locationManager.startUpdatingLocation()
        self.isTracking = true
    }

    func stopTracking() {
        self.locationManager.stopUpdatingLocation()
        self.isTracking = false
    }

    func setFrequency(minutes: Double) {
        // This is a simplistic way to handle frequency.
        // For a real app, you might want a more sophisticated solution
        // involving timers and significant location change monitoring.
        // For now, we'll just adjust the desiredAccuracy and distanceFilter.
        // A high frequency means high accuracy.
        if minutes < 5 {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
        } else if minutes < 15 {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.distanceFilter = 1000
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        didUpdateLocation?(location)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if isTracking {
                startTracking()
            }
        case .denied, .restricted:
            stopTracking()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
