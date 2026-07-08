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
    private var locationUpdateTimeoutTask: Task<Void, Never>?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            pendingContinuations.append(continuation)
            guard !isRequestInFlight else { return }

            isRequestInFlight = true
            beginLocationRequest()
        }
    }

    func warmUpAuthorizationIfNeeded() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    private func beginLocationRequest() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestFreshLocation()
        case .denied, .restricted:
            resumeAll(throwing: BigDoseLocationError.denied)
        @unknown default:
            resumeAll(throwing: BigDoseLocationError.unavailable)
        }
    }

    private func requestFreshLocation() {
        locationUnknownRetryCount = 0
        manager.startUpdatingLocation()
        locationUpdateTimeoutTask?.cancel()
        locationUpdateTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, self.isRequestInFlight else { return }
            self.manager.stopUpdatingLocation()
            if let cachedLocation = self.manager.location {
                self.resumeAll(returning: cachedLocation)
            } else {
                self.resumeAll(throwing: BigDoseLocationError.unavailable)
            }
        }
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRequestInFlight else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestFreshLocation()
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
        manager.stopUpdatingLocation()
        locationUpdateTimeoutTask?.cancel()
        locationUpdateTimeoutTask = nil
        resumeAll(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .locationUnknown {
            if let cachedLocation = manager.location {
                locationUnknownRetryCount = 0
                manager.stopUpdatingLocation()
                locationUpdateTimeoutTask?.cancel()
                locationUpdateTimeoutTask = nil
                resumeAll(returning: cachedLocation)
                return
            }

            if locationUnknownRetryCount < 4 {
                locationUnknownRetryCount += 1
                manager.requestLocation()
                return
            }
        }

        locationUnknownRetryCount = 0
        manager.stopUpdatingLocation()
        locationUpdateTimeoutTask?.cancel()
        locationUpdateTimeoutTask = nil
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
        manager.stopUpdatingLocation()
        locationUpdateTimeoutTask?.cancel()
        locationUpdateTimeoutTask = nil

        for continuation in continuations {
            continuation.resume(throwing: error)
        }
    }
}
