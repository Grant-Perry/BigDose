import SwiftData
import SwiftUI

@main
struct BigDoseApp: App {
    let modelContainer: ModelContainer

    init() {
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
        }
        .modelContainer(modelContainer)
    }
}
