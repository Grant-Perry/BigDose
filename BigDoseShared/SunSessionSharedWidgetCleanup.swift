import Foundation
import WidgetKit

enum SunSessionSharedWidgetCleanup {
    nonisolated static func clearActiveSessionAndReload() {
        guard var snapshot = BigDoseWidgetSnapshotStore.load() else { return }
        snapshot.activeSession = nil
        snapshot.generatedAt = .now
        BigDoseWidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: BigDoseWidgetKind.home)
    }
}
