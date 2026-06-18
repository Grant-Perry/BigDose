import SwiftData
import SwiftUI

struct BigDoseRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var appState = BigDoseAppState()

    private var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
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
                }
                .tint(.solarGold)
            } else {
                BigDoseLaunchLoadingView()
            }
        }
        .task {
            await ensureProfileExists()
        }
        .task(id: profile?.persistentModelID) {
            guard let profile, profile.isOnboardingComplete else { return }
            await BigDoseNotificationCoordinator.refreshManagedAlerts(
                profile: profile,
                modelContext: modelContext
            )
        }
        .fullScreenCover(isPresented: $appState.isShowingOnboarding) {
            OnboardingView(profile: profile)
        }
    }

    private func ensureProfileExists() async {
        guard profiles.isEmpty else {
            appState.isShowingOnboarding = profiles.first?.isOnboardingComplete == false
            return
        }

        let profile = UserProfile()
        modelContext.insert(profile)
        try? modelContext.save()
        appState.isShowingOnboarding = true
    }
}

private struct BigDoseLaunchLoadingView: View {
    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ProgressView("Preparing BigDose")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .tint(.solarGold)
        }
    }
}

#Preview {
    BigDoseRootView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
