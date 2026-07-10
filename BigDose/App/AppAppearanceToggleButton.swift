import SwiftUI

struct AppAppearanceToggleButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppAppearancePreference.storageKey)
    private var appAppearanceRawValue = AppAppearancePreference.system.rawValue

    var body: some View {
        Button(
            accessibilityLabel,
            systemImage: symbolName,
            action: toggleAppearance
        )
        .labelStyle(.iconOnly)
        .accessibilityHint("Overrides the system appearance and remembers your choice")
    }

    private var accessibilityLabel: String {
        colorScheme == .dark ? "Use light appearance" : "Use dark appearance"
    }

    private var symbolName: String {
        colorScheme == .dark ? "sun.max.fill" : "moon.fill"
    }

    private func toggleAppearance() {
        appAppearanceRawValue = colorScheme == .dark
            ? AppAppearancePreference.light.rawValue
            : AppAppearancePreference.dark.rawValue
    }
}
