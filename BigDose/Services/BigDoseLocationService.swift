import CoreLocation
import Foundation

enum BigDoseLocationError: Error {
    case unavailable
    case denied
}

struct BigDoseResolvedLocation: Sendable {
    var location: CLLocation
    var isApproximate: Bool
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

    /// Precise GPS when available; otherwise last known / locale-based coordinates when authorization allows.
    func resolveLocationForWeather() async throws -> BigDoseResolvedLocation {
        do {
            let location = try await requestCurrentLocation()
            BigDoseLocationCache.save(location)
            return BigDoseResolvedLocation(
                location: location,
                isApproximate: !Self.isFreshSessionLocation(location)
            )
        } catch BigDoseLocationError.denied {
            throw BigDoseLocationError.denied
        } catch {
            if let cached = BigDoseLocationCache.load() ?? manager.location {
                return BigDoseResolvedLocation(location: cached, isApproximate: true)
            }

            // Authorized but no fix yet (common on cold iPad / App Review). Still load WeatherKit.
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                let fallback = Self.localeApproximateLocation()
                return BigDoseResolvedLocation(location: fallback, isApproximate: true)
            }

            throw error
        }
    }

    /// Coarse city-level coordinate from the device locale so weather can load before GPS settles.
    static func localeApproximateLocation() -> CLLocation {
        let region = Locale.current.region?.identifier.uppercased() ?? "US"

        let coordinate: (lat: Double, lon: Double) = switch region {
        case "US": (37.3349, -122.0090) // Cupertino — Apple review default
        case "CA": (43.6532, -79.3832)
        case "GB": (51.5074, -0.1278)
        case "AU": (-33.8688, 151.2093)
        case "NZ": (-36.8485, 174.7633)
        case "IE": (53.3498, -6.2603)
        case "DE": (52.5200, 13.4050)
        case "FR": (48.8566, 2.3522)
        case "JP": (35.6762, 139.6503)
        default: (37.3349, -122.0090)
        }

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon),
            altitude: 0,
            horizontalAccuracy: 50_000,
            verticalAccuracy: -1,
            timestamp: .now
        )
    }

    private static func isFreshSessionLocation(_ location: CLLocation, now: Date = .now) -> Bool {
        location.horizontalAccuracy >= 0
            && location.horizontalAccuracy <= 1_000
            && abs(now.timeIntervalSince(location.timestamp)) <= 5 * 60
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
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.startUpdatingLocation()
        locationUpdateTimeoutTask?.cancel()
        locationUpdateTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard let self, self.isRequestInFlight else { return }

            if let cachedLocation = self.bestAvailableLocation() {
                self.manager.stopUpdatingLocation()
                BigDoseLocationCache.save(cachedLocation)
                self.resumeAll(returning: cachedLocation)
                return
            }

            // One more pass at coarser accuracy before failing.
            self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager.requestLocation()

            try? await Task.sleep(for: .seconds(6))
            guard self.isRequestInFlight else { return }
            self.manager.stopUpdatingLocation()

            if let cachedLocation = self.bestAvailableLocation() {
                BigDoseLocationCache.save(cachedLocation)
                self.resumeAll(returning: cachedLocation)
            } else {
                self.resumeAll(throwing: BigDoseLocationError.unavailable)
            }
        }
        manager.requestLocation()
    }

    private func bestAvailableLocation() -> CLLocation? {
        if let live = manager.location, live.horizontalAccuracy >= 0 {
            return live
        }
        return BigDoseLocationCache.load()
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
        BigDoseLocationCache.save(location)
        resumeAll(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .locationUnknown {
            if let cachedLocation = bestAvailableLocation() {
                locationUnknownRetryCount = 0
                manager.stopUpdatingLocation()
                locationUpdateTimeoutTask?.cancel()
                locationUpdateTimeoutTask = nil
                BigDoseLocationCache.save(cachedLocation)
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

        if let cachedLocation = bestAvailableLocation() {
            BigDoseLocationCache.save(cachedLocation)
            resumeAll(returning: cachedLocation)
            return
        }

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
