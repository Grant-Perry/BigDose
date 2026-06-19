import SwiftData
import SwiftUI

@main
struct BigDoseApp: App {
    let modelContainer: ModelContainer

    init() {
        SunSessionLiveActivityCoordinator.registerDefaultPreferences()
        BigDoseNavigationAppearance.configure()
        BigDoseNotifications.configure()

        do {
            modelContainer = try BigDoseModelContainerFactory.make()
        } catch {
            fatalError("Failed to create BigDose model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            BigDoseRootView()
                .onOpenURL(perform: handleIncomingURL)
        }
        .modelContainer(modelContainer)
    }

    private func handleIncomingURL(_ url: URL) {
        if let sessionID = SunSessionActivityAttributes.sessionID(fromDeepLink: url) {
            NotificationCenter.default.post(
                name: .bigDoseOpenSessionFromLiveActivity,
                object: sessionID
            )
        }
    }
}
