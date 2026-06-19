import Foundation

enum BigDoseWidgetSnapshotStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    nonisolated static func load() -> BigDoseWidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier),
            let data = defaults.data(forKey: BigDoseAppGroup.widgetSnapshotKey)
        else {
            return nil
        }

        return try? decoder.decode(BigDoseWidgetSnapshot.self, from: data)
    }

    nonisolated static func save(_ snapshot: BigDoseWidgetSnapshot) {
        guard
            let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier),
            let data = try? encoder.encode(snapshot)
        else {
            return
        }

        defaults.set(data, forKey: BigDoseAppGroup.widgetSnapshotKey)
    }
}
