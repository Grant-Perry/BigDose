import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    var profile: UserProfile?

    @State private var resetOnboardingStep: ResetOnboardingStep = .none
    @State private var isShowingOnboarding = false

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    sessionSafetyCard
                    notificationsCard
                    manageDataCard
                    medicalCard
                    resetOnboardingCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reset onboarding?",
            isPresented: isPresented(for: .firstConfirm),
            titleVisibility: .visible
        ) {
            Button("Continue") {
                resetOnboardingStep = .finalConfirm
            }
            Button("Cancel", role: .cancel) {
                resetOnboardingStep = .none
            }
        } message: {
            Text("This sends you back through the full setup flow. Your saved sessions, labs, supplements, and progress stay on this device.")
        }
        .confirmationDialog(
            "Are you absolutely certain?",
            isPresented: isPresented(for: .finalConfirm),
            titleVisibility: .visible
        ) {
            Button("Reset Onboarding", role: .destructive) {
                resetOnboarding()
                resetOnboardingStep = .none
            }
            Button("Cancel", role: .cancel) {
                resetOnboardingStep = .none
            }
        } message: {
            Text("This will clear your onboarding completion and wellness disclaimer acceptance. You must walk through setup again before BigDose treats your profile as ready.")
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

    private var resetOnboardingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Onboarding", systemImage: "exclamationmark.triangle.fill")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.solarOrange)

                Text("Only use this if you need to rerun setup from scratch. BigDose will ask you to confirm twice before continuing.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Button(role: .destructive) {
                    resetOnboardingStep = .firstConfirm
                } label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
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
                        .font(.bigDoseHeader(.title2).weight(.semibold))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How BigDose Works")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Review the plain-language science and non-medical boundaries.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var sessionSafetyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Session Safety", systemImage: "shield.lefthalf.filled")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("How far ahead of the exit alert BigDose warns you to start packing up and moving inside.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                if let profile {
                    Stepper(value: prepareExitLeadPercentBinding, in: UserProfile.prepareExitLeadPercentRange, step: 5) {
                        Text("Exit prep warning: \(profile.prepareExitLeadPercent)%")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .tint(.solarGold)

                    Text("At \(profile.prepareExitLeadPercent)%, \"Get ready to exit sun\" fires that much before the stop alert — for example, about \(profile.prepareExitLeadPercent)% of the time left to exit.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }
            }
        }
    }

    private var prepareExitLeadPercentBinding: Binding<Int> {
        Binding {
            profile?.prepareExitLeadPercent ?? 20
        } set: { value in
            profile?.prepareExitLeadPercent = UserProfile.clampedPrepareExitLeadPercent(value)
            profile?.updatedAt = .now
            try? modelContext.save()
        }
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

    private func isPresented(for step: ResetOnboardingStep) -> Binding<Bool> {
        Binding {
            resetOnboardingStep == step
        } set: { isPresented in
            if !isPresented, resetOnboardingStep == step {
                resetOnboardingStep = .none
            }
        }
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

private enum ResetOnboardingStep {
    case none
    case firstConfirm
    case finalConfirm
}

#Preview {
    NavigationStack {
        SettingsView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
