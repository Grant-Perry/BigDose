import Observation

@Observable
@MainActor
final class BigDoseAppState {
    var selectedTab: AppTab = .home
    var isShowingOnboarding = false
}
