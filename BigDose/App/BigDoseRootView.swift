import SwiftData
import SwiftUI

struct BigDoseRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var appState = BigDoseAppState()
    @State private var healthKitImportService = HealthKitImportService()

    private var profile: UserProfile? {
        UserProfile.canonical(from: profiles)
    }

    var body: some View {
        ZStack {
            Group {
                if let profile {
                    TabView(selection: $appState.selectedTab) {
                        Tab(AppTab.home.title, systemImage: AppTab.home.symbolName, value: .home) {
                            HomeView(profile: profile)
                        }

                        Tab(AppTab.history.title, systemImage: AppTab.history.symbolName, value: .history) {
                            HistoryView()
                        }

                        Tab(AppTab.progress.title, systemImage: AppTab.progress.symbolName, value: .progress) {
                            ProgressDashboardView(profile: profile)
                        }

                        Tab(AppTab.profile.title, systemImage: AppTab.profile.symbolName, value: .profile) {
                            ProfileView()
                        }

                        Tab(AppTab.settings.title, systemImage: AppTab.settings.symbolName, value: .settings) {
                            SettingsTabView(profile: profile)
                        }
                    }
                    .tint(.solarGold)
                } else {
                    BigDoseLaunchLoadingView()
                }
            }
            .environment(appState)

            if appState.isShowingSplash {
                BigDoseSplashScreenView {
                    appState.isShowingSplash = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: appState.isShowingSplash)
        .task {
            await ensureProfileExists()
            removeRedundantBootstrapProfiles()
            presentOnboardingIfNeeded()
        }
        .onChange(of: appState.isShowingSplash) { _, isShowing in
            guard !isShowing else { return }
            presentOnboardingIfNeeded()
        }
        .onChange(of: profile?.persistentModelID) { _, _ in
            presentOnboardingIfNeeded()
        }
        .onChange(of: profiles.count) { _, _ in
            removeRedundantBootstrapProfiles()
        }
        .task(id: profile?.persistentModelID) {
            guard let profile else { return }
            OptimalDailyIUMigration.applyIfNeeded(to: profile, modelContext: modelContext)
            guard profile.isOnboardingComplete else { return }
            await BigDoseNotificationCoordinator.refreshManagedAlerts(
                profile: profile,
                modelContext: modelContext
            )
            await healthKitImportService.silentRefreshIfNeeded(
                profile: profile,
                modelContext: modelContext
            )
        }
        .fullScreenCover(isPresented: $appState.isShowingOnboarding) {
            if let profile {
                OnboardingView(profile: profile, onFinished: completeOnboardingPresentation)
            }
        }
        .onChange(of: profile?.isOnboardingComplete) { _, isComplete in
            guard isComplete == true else { return }
            completeOnboardingPresentation()
        }
    }

    private func completeOnboardingPresentation() {
        appState.selectedTab = .home
        appState.isShowingOnboarding = false
    }

    private func presentOnboardingIfNeeded() {
        guard !appState.isShowingSplash else { return }
        guard let profile else { return }
        appState.isShowingOnboarding = !profile.isOnboardingComplete
    }

    private func ensureProfileExists() async {
        guard profiles.isEmpty else { return }

        let profile = UserProfile()
        modelContext.insert(profile)
        try? modelContext.save()
    }

    private func removeRedundantBootstrapProfiles() {
        guard let canonical = UserProfile.canonical(from: profiles), canonical.isOnboardingComplete else { return }

        let redundant = profiles.filter {
            $0.persistentModelID != canonical.persistentModelID && $0.isEmptyBootstrapProfile()
        }
        guard !redundant.isEmpty else { return }

        for profile in redundant {
            modelContext.delete(profile)
        }
        try? modelContext.save()
    }
}

private struct BigDoseLaunchLoadingView: View {
    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ProgressView("Preparing BigDose")
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .tint(.solarGold)
        }
    }
}

#Preview {
    BigDoseRootView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
