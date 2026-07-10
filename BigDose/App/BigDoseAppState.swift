import Observation

@Observable
@MainActor
final class BigDoseAppState {
    var selectedTab: AppTab = .home
    var isShowingOnboarding = false
    /// Shown once per cold launch, before onboarding or the main tabs.
    var isShowingSplash = true
}
