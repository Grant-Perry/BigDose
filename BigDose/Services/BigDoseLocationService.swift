import CoreLocation
import Foundation

enum BigDoseLocationError: Error {
    case unavailable
    case denied
}

@MainActor
final class BigDoseLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pendingContinuations: [CheckedContinuation<CLLocation, Error>] = []
    private var isRequestInFlight = false
    private var locationUnknownRetryCount = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            pendingContinuations.append(continuation)
            guard !isRequestInFlight else { return }

            isRequestInFlight = true
            beginLocationRequest()
        }
    }

    private func beginLocationRequest() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resumeAll(throwing: BigDoseLocationError.denied)
        @unknown default:
            resumeAll(throwing: BigDoseLocationError.unavailable)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRequestInFlight else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resumeAll(throwing: BigDoseLocationError.denied)
        case .notDetermined:
            break
        @unknown default:
            resumeAll(throwing: BigDoseLocationError.unavailable)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resumeAll(throwing: BigDoseLocationError.unavailable)
            return
        }

        locationUnknownRetryCount = 0
        resumeAll(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .locationUnknown {
            if let cachedLocation = manager.location {
                locationUnknownRetryCount = 0
                resumeAll(returning: cachedLocation)
                return
            }

            if locationUnknownRetryCount < 2 {
                locationUnknownRetryCount += 1
                manager.requestLocation()
                return
            }
        }

        locationUnknownRetryCount = 0
        resumeAll(throwing: error)
    }

    private func resumeAll(returning location: CLLocation) {
        let continuations = pendingContinuations
        pendingContinuations = []
        isRequestInFlight = false

        for continuation in continuations {
            continuation.resume(returning: location)
        }
    }

    private func resumeAll(throwing error: Error) {
        let continuations = pendingContinuations
        pendingContinuations = []
        isRequestInFlight = false

        for continuation in continuations {
            continuation.resume(throwing: error)
        }
    }
}
