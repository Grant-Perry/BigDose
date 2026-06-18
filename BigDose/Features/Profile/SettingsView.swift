import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    var profile: UserProfile?

    @State private var isShowingResetConfirmation = false
    @State private var isShowingOnboarding = false

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    onboardingCard
                    notificationsCard
                    manageDataCard
                    medicalCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .confirmationDialog("Reset onboarding?", isPresented: $isShowingResetConfirmation) {
            Button("Reset Onboarding", role: .destructive) {
                resetOnboarding()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reopen onboarding so you can retake the setup flow. Your stored profile values remain editable through onboarding.")
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(profile: profile)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Control setup, education, and safety framing.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var onboardingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Onboarding", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Run the setup flow again to adjust your name, birth date, sex, body context, skin type, sun habits, and disclaimer acknowledgement.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Button(role: .destructive) {
                    isShowingResetConfirmation = true
                } label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.solarOrange)
            }
        }
    }

    private var medicalCard: some View {
        NavigationLink {
            EducationView()
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    Image(systemName: "cross.case.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How BigDose Works")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Review the plain-language science and non-medical boundaries.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var notificationsCard: some View {
        NavigationLink {
            NotificationSettingsView(profile: profile)
        } label: {
            GlassCard {
                ProfileLinkRow(title: "Notifications", detail: "Alert categories, reminders, and quiet hours", systemImage: "bell.badge.fill")
            }
        }
        .buttonStyle(.plain)
    }

    private var manageDataCard: some View {
        NavigationLink {
            ManageDataView(profile: profile)
        } label: {
            GlassCard {
                ProfileLinkRow(title: "Manage Data", detail: "Export, restore, iCloud, and Apple Health", systemImage: "externaldrive.fill")
            }
        }
        .buttonStyle(.plain)
    }

    private func resetOnboarding() {
        guard let profile else {
            isShowingOnboarding = true
            return
        }

        profile.isOnboardingComplete = false
        profile.hasAcceptedWellnessDisclaimer = false
        profile.updatedAt = .now
        try? modelContext.save()
        isShowingOnboarding = true
    }
}

#Preview {
    NavigationStack {
        SettingsView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
