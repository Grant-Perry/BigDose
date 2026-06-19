import SwiftUI

// MARK: - Onboarding Page

struct OnboardingAppleHealthPage: View {
    var isSyncing = false
    var onSync: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image("AppleHealthAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
                    .accessibilityLabel("Apple Health app icon")

                Text("Automatically sync your data with Apple Health.")
                    .font(.system(.largeTitle, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Using BigDose with the Apple Health app on iPhone can fill your profile, suggest a default supplement amount from recent vitamin D entries, review outdoor workouts, and keep sunlight history alongside the rest of your health data. BigDose reads only what you allow.")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onSync) {
                    Group {
                        if isSyncing {
                            ProgressView()
                                .tint(.solarOrange)
                        } else {
                            Text("Sync Health Data")
                                .font(.bigDoseHeader(.headline).weight(.semibold))
                                .foregroundStyle(.solarOrange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)
                .accessibilityLabel(isSyncing ? "Syncing Apple Health data" : "Sync Health Data")

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

// MARK: - Attribution

struct AppleHealthKitAttributionView: View {
    var body: some View {
        Text("Health data is accessed through Apple HealthKit and the Apple Health app. Apple, Health, and HealthKit are trademarks of Apple Inc., registered in the U.S. and other countries.")
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
