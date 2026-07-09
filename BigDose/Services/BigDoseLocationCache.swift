import CoreLocation
import Foundation

enum BigDoseLocationCache {
    private static let latitudeKey = "bigDose.lastLocation.latitude"
    private static let longitudeKey = "bigDose.lastLocation.longitude"
    private static let accuracyKey = "bigDose.lastLocation.horizontalAccuracy"
    private static let timestampKey = "bigDose.lastLocation.timestamp"

    static func save(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else { return }

        UserDefaults.standard.set(location.coordinate.latitude, forKey: latitudeKey)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: longitudeKey)
        UserDefaults.standard.set(location.horizontalAccuracy, forKey: accuracyKey)
        UserDefaults.standard.set(location.timestamp.timeIntervalSince1970, forKey: timestampKey)
    }

    static func load() -> CLLocation? {
        let defaults = UserDefaults.standard
        guard
            defaults.object(forKey: latitudeKey) != nil,
            defaults.object(forKey: longitudeKey) != nil
        else {
            return nil
        }

        let latitude = defaults.double(forKey: latitudeKey)
        let longitude = defaults.double(forKey: longitudeKey)
        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            return nil
        }

        let accuracy = defaults.object(forKey: accuracyKey) as? Double ?? 1_000
        let timestamp = Date(
            timeIntervalSince1970: defaults.object(forKey: timestampKey) as? TimeInterval ?? 0
        )

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: max(accuracy, 1),
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}
