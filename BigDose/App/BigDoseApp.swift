import SwiftData
import SwiftUI

@main
struct BigDoseApp: App {
    @AppStorage(AppAppearancePreference.storageKey)
    private var appAppearanceRawValue = AppAppearancePreference.system.rawValue

    let modelContainer: ModelContainer
    let storeStartupError: String?

    init() {
        SunSessionLiveActivityCoordinator.registerDefaultPreferences()
        BigDoseNavigationAppearance.configure()
        BigDoseNotifications.configure()

        do {
            modelContainer = try BigDoseModelContainerFactory.make()
            storeStartupError = nil
        } catch {
            storeStartupError = error.localizedDescription
            do {
                modelContainer = try BigDoseModelContainerFactory.make(inMemory: true)
            } catch {
                fatalError("Failed to create BigDose recovery container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let storeStartupError {
                    BigDoseStoreRecoveryView(message: storeStartupError)
                } else {
                    BigDoseRootView()
                        .onOpenURL(perform: handleIncomingURL)
                }
            }
            .preferredColorScheme(appAppearance.colorScheme)
        }
        .modelContainer(modelContainer)
    }

    private var appAppearance: AppAppearancePreference {
        AppAppearancePreference(rawValue: appAppearanceRawValue) ?? .system
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

private struct BigDoseStoreRecoveryView: View {
    var message: String

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 18) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.solarGold)

                Text("Data Recovery Needed")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)

                Text("BigDose did not reset the database. Update to the latest build or contact support before making further changes.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }
}
