import SwiftUI

// MARK: - Onboarding Page

struct OnboardingAppleHealthPage: View {
    var isSyncing = false
    var onSync: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Automatically sync your data with Apple Health.")
                    .font(.bigDoseHeader(.largeTitle))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Using BigDose with the Apple Health app on iPhone can fill your profile, suggest a default supplement amount from recent vitamin D entries, review outdoor workouts, sync Apple Watch Time in Daylight as incidental sun and keep sunlight history alongside the rest of your health data. BigDose reads only what you allow.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onSync) {
                    HStack(spacing: 12) {
                        Group {
                            if isSyncing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image("AppleHealthAppIcon")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.22), radius: 8, y: 4)

                        Text("Sync Now")
                            .font(.bigDoseHeader(.title2).weight(.black))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)
                .accessibilityLabel(isSyncing ? "Syncing Apple Health data" : "Sync Apple Health data now")

                Button("Skip for Now", action: onSkip)
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .disabled(isSyncing)

                Image("WorksWithAppleHealth")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 34)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Works with Apple Health")

                AppleHealthKitAttributionView()
            }
            .padding(22)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Banner Button

struct AppleHealthBannerButton: View {
    var isEnabled = true
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("WorksWithAppleHealth")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .opacity(isLoading ? 0.72 : 1)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .controlSize(.regular)
                            .tint(.white)
                    }
                }
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(isLoading ? "Checking Apple Health" : "Connect with Apple Health")
        .accessibilityHint("Opens Apple Health permission and import options.")
    }
}

// MARK: - Action Section

struct AppleHealthKitActionSection: View {
    var caption: String
    var isLoading = false
    var isEnabled = true
    var showsAttribution = true
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(caption)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)

            AppleHealthBannerButton(isEnabled: isEnabled, isLoading: isLoading, action: action)

            if showsAttribution {
                AppleHealthKitAttributionView()
            }
        }
    }
}

// MARK: - Inline Refresh

struct AppleHealthRefreshButton: View {
    var isRefreshing = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image("AppleHealthAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipShape(.rect(cornerRadius: 4, style: .continuous))

                Image(systemName: "arrow.clockwise")
                    .font(.caption2.weight(.bold))
                    .symbolEffect(.rotate, isActive: isRefreshing)
            }
            .foregroundStyle(.white.opacity(isRefreshing ? 0.42 : 0.68))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.08), in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .accessibilityLabel(isRefreshing ? "Refreshing Apple Health sun data" : "Refresh Apple Health sun data")
    }
}

// MARK: - Attribution

struct AppleHealthKitAttributionView: View {
    var body: some View {
        Text("Health data is accessed through Apple HealthKit and the Apple Health app. Apple, Health and HealthKit are trademarks of Apple Inc., registered in the U.S. and other countries.")
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white.opacity(0.48))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Apple HealthKit attribution")
    }
}

// MARK: - Navigation Row

struct AppleHealthNavigationRow: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("WorksWithAppleHealth")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220, maxHeight: 34, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.bigDoseHeader(.headline).weight(.black))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
        .accessibilityAddTraits(.isButton)
    }
}
