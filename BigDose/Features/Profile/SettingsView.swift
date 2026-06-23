import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(BigDoseAppState.self) private var appState
    var profile: UserProfile?

    @State private var confirmationStep: SettingsConfirmationStep = .none
    @State private var isShowingOnboarding = false
    @State private var onboardingProfile: UserProfile?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    sessionSafetyCard
                    dailySupplementCard
                    notificationsCard
                    manageDataCard
                    medicalCard
                    onboardingControlsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .bigDoseAlert(
            "Reset onboarding?",
            isPresented: isPresented(for: .resetOnboarding),
            message: "This sends you back through setup. Your sessions, labs, supplements and progress stay on this device.",
            actions: [
                .destructive("Reset Onboarding") {
                    resetOnboarding()
                    confirmationStep = .none
                },
                .cancel("Cancel") {
                    confirmationStep = .none
                }
            ]
        )
        .bigDoseAlert(
            "Nuke all BigDose data?",
            isPresented: isPresented(for: .nukeFirstConfirm),
            message: "This permanently deletes your profile, sessions, labs, supplements, imports and progress on this device.",
            actions: [
                .default("Continue") {
                    confirmationStep = .nukeFinalConfirm
                },
                .cancel("Cancel") {
                    confirmationStep = .none
                }
            ]
        )
        .bigDoseAlert(
            "Are you absolutely certain?",
            isPresented: isPresented(for: .nukeFinalConfirm),
            message: "There is no undo. BigDose will erase everything local and send you through onboarding from scratch.",
            actions: [
                .destructive("Nuke All Data") {
                    nukeAllData()
                    confirmationStep = .none
                },
                .cancel("Cancel") {
                    confirmationStep = .none
                }
            ]
        )
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(profile: onboardingProfile ?? profile, onFinished: completeOnboardingPresentation)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Control setup, education and safety framing.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var onboardingControlsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Onboarding & Data", systemImage: "exclamationmark.triangle.fill")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.solarOrange)

                Text("Reset onboarding reruns setup without deleting your saved data. Nuke wipes everything local and starts completely fresh.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Button(role: .destructive) {
                    confirmationStep = .resetOnboarding
                } label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.solarOrange)

                Button(role: .destructive) {
                    confirmationStep = .nukeFirstConfirm
                } label: {
                    Label("Nuke All Data", systemImage: "trash.fill")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
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
                    Toggle("Nanny", isOn: wantsNannyModeBinding)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)
                        .tint(.solarGold)

                    Text("When on, BigDose keeps warning every percent past 90% MED (Risk) while you stay out. When off, you still get the 90% guidance alert and over-limit tracking — just not the repeat nagging.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))

                    Divider()
                        .overlay(.white.opacity(0.12))

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

    private var dailySupplementCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Daily Supplement", systemImage: "pills.fill")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                if let profile {
                    Toggle("Auto-apply daily supplement IU", isOn: autoApplyDailySupplementBinding)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)
                        .tint(.solarGold)

                    Text("When on, BigDose logs your \(profile.defaultSupplementIU) IU default toward each day's total. When off, nothing is counted until you log manually.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }
            }
        }
    }

    private var autoApplyDailySupplementBinding: Binding<Bool> {
        Binding {
            profile?.autoApplyDailySupplementIU ?? true
        } set: { value in
            profile?.autoApplyDailySupplementIU = value
            profile?.updatedAt = .now
            try? modelContext.save()
        }
    }

    private var wantsNannyModeBinding: Binding<Bool> {
        Binding {
            profile?.wantsNannyMode ?? true
        } set: { value in
            profile?.wantsNannyMode = value
            profile?.updatedAt = .now
            try? modelContext.save()
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
                ProfileLinkRow(title: "Notifications", detail: "Alert categories, reminders and quiet hours", systemImage: "bell.badge.fill")
            }
        }
        .buttonStyle(.plain)
    }

    private var manageDataCard: some View {
        NavigationLink {
            ManageDataView(profile: profile)
        } label: {
            GlassCard {
                ProfileLinkRow(title: "Manage Data", detail: "Export, restore, iCloud and Apple Health", systemImage: "externaldrive.fill")
            }
        }
        .buttonStyle(.plain)
    }

    private func isPresented(for step: SettingsConfirmationStep) -> Binding<Bool> {
        Binding {
            confirmationStep == step
        } set: { isPresented in
            if !isPresented, confirmationStep == step {
                confirmationStep = .none
            }
        }
    }

    private func completeOnboardingPresentation() {
        appState.selectedTab = .home
        appState.isShowingOnboarding = false
        isShowingOnboarding = false
        onboardingProfile = nil
    }

    private func resetOnboarding() {
        guard let profile else {
            onboardingProfile = nil
            isShowingOnboarding = true
            return
        }

        profile.isOnboardingComplete = false
        profile.hasAcceptedWellnessDisclaimer = false
        profile.updatedAt = .now
        try? modelContext.save()
        onboardingProfile = profile
        isShowingOnboarding = true
    }

    private func nukeAllData() {
        do {
            let freshProfile = try BigDoseLocalDataReset.nukeAndCreateFreshProfile(in: modelContext)
            onboardingProfile = freshProfile
            isShowingOnboarding = true
        } catch {
            return
        }
    }
}

private enum SettingsConfirmationStep {
    case none
    case resetOnboarding
    case nukeFirstConfirm
    case nukeFinalConfirm
}

#Preview {
    NavigationStack {
        SettingsView(profile: .preview)
            .environment(BigDoseAppState())
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
