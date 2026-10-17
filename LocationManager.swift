import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {

    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {

        authorizationStatus =
            manager.authorizationStatus

        super.init()

        manager.delegate = self

        manager.desiredAccuracy =
            kCLLocationAccuracyBest

        manager.distanceFilter = 5
    }

    // MARK: - Request Permission

    func requestPermission() {

        manager.requestWhenInUseAuthorization()
    }

    // MARK: - Start Location Updates

    func startUpdatingLocation() {

        guard
            authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
        else {

            requestPermission()

            return
        }

        manager.startUpdatingLocation()
    }

    // MARK: - Stop Location Updates

    func stopUpdatingLocation() {

        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        DispatchQueue.main.async {

            self.authorizationStatus =
                manager.authorizationStatus

            switch manager.authorizationStatus {

            case .authorizedWhenInUse,
                 .authorizedAlways:

                self.startUpdatingLocation()

            default:

                break
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let latestLocation =
            locations.last
        else {
            return
        }

        DispatchQueue.main.async {

            self.location = latestLocation
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print(
            "Location error: \(error.localizedDescription)"
        )
    }
}
