import CoreLocation
import Foundation

enum BigDoseLocationError: Error {
    case unavailable
    case denied
}

@MainActor
final class BigDoseLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var locationUnknownRetryCount = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                resume(throwing: BigDoseLocationError.denied)
            @unknown default:
                resume(throwing: BigDoseLocationError.unavailable)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resume(throwing: BigDoseLocationError.denied)
        case .notDetermined:
            break
        @unknown default:
            resume(throwing: BigDoseLocationError.unavailable)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resume(throwing: BigDoseLocationError.unavailable)
            return
        }

        locationUnknownRetryCount = 0
        resume(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .locationUnknown {
            if let cachedLocation = manager.location {
                locationUnknownRetryCount = 0
                resume(returning: cachedLocation)
                return
            }

            if locationUnknownRetryCount < 2 {
                locationUnknownRetryCount += 1
                manager.requestLocation()
                return
            }
        }

        locationUnknownRetryCount = 0
        resume(throwing: error)
    }

    private func resume(returning location: CLLocation) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
