import SwiftData
import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    @Query(sort: \DailySunPlan.generatedAt, order: .reverse) private var dailyPlans: [DailySunPlan]
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var profile: UserProfile?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    permissionCard

                    if let profile {
                        alertCard(profile)
                        quietHoursCard(profile)
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Notifications")
        .toolbarTitleDisplayMode(.inline)
        .task {
            authorizationStatus = await BigDoseAlertScheduler.authorizationStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notifications")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Choose which BigDose guidance can reach you and when.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var permissionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Permission: \(authorizationStatusTitle)", systemImage: "bell.badge.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                switch authorizationStatus {
                case .notDetermined:
                    Button {
                        Task {
                            _ = await BigDoseAlertScheduler.requestAuthorization()
                            authorizationStatus = await BigDoseAlertScheduler.authorizationStatus()
                            await reschedule()
                        }
                    } label: {
                        Text("Allow Notifications")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.solarOrange)

                case .denied:
                    Text("Notifications are off in Settings. Turn them on in iOS Settings if you want BigDose reminders.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))

                default:
                    Text("BigDose will schedule reminders automatically when an enabled alert has something useful to say.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private func alertCard(_ profile: UserProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Useful sunlight windows", isOn: binding(\.wantsSolarWindowAlerts))
                Toggle("Session safety guidance", isOn: binding(\.wantsRiskAlerts))
                Toggle("Supplement reminders", isOn: binding(\.wantsSupplementReminders))
                Toggle("Lab retest reminders", isOn: binding(\.wantsLabReminders))
                Toggle("Weekly progress", isOn: binding(\.wantsWeeklyProgressAlerts))
                Toggle("Level trend notices", isOn: binding(\.wantsLevelTrendAlerts))
                Toggle("Milestones", isOn: binding(\.wantsMilestoneAlerts))
                Toggle("Weather break alerts", isOn: binding(\.wantsWeatherBreakAlerts))
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .tint(.solarGold)
        }
    }

    private func quietHoursCard(_ profile: UserProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Quiet hours", isOn: binding(\.quietHoursEnabled))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .tint(.solarGold)

                Stepper("Start: \(hourLabel(profile.quietHoursStartHour))", value: binding(\.quietHoursStartHour), in: 0...23)
                Stepper("End: \(hourLabel(profile.quietHoursEndHour))", value: binding(\.quietHoursEndHour), in: 0...23)
                Stepper("Supplement: \(hourLabel(profile.supplementReminderHour))", value: binding(\.supplementReminderHour), in: 0...23)
                Stepper("Lab cadence: \(profile.labReminderIntervalDays) days", value: binding(\.labReminderIntervalDays), in: 30...365, step: 30)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
        }
    }

    private var authorizationStatusTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            "Not asked"
        case .denied:
            "Denied"
        case .authorized:
            "Allowed"
        case .provisional:
            "Provisional"
        case .ephemeral:
            "Ephemeral"
        @unknown default:
            "Unknown"
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let normalizedHour = ((hour % 24) + 24) % 24
        let suffix = normalizedHour < 12 ? "AM" : "PM"
        let displayHour = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12
        return "\(displayHour):00 \(suffix)"
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding {
            profile?[keyPath: keyPath] ?? false
        } set: { value in
            profile?[keyPath: keyPath] = value
            saveAndReschedule()
        }
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<UserProfile, Int>) -> Binding<Int> {
        Binding {
            profile?[keyPath: keyPath] ?? 0
        } set: { value in
            profile?[keyPath: keyPath] = value
            saveAndReschedule()
        }
    }

    private func saveAndReschedule() {
        profile?.wantsWindowReminders = profile?.wantsSolarWindowAlerts ?? false
        profile?.updatedAt = .now
        try? modelContext.save()
        Task { await reschedule() }
    }

    private func reschedule() async {
        guard let profile else { return }
        let progress = ProgressAggregationService.snapshot(
            profile: profile,
            sessions: sessions,
            supplements: supplements,
            foods: foods,
            labs: labs
        )
        await BigDoseAlertScheduler.reschedule(profile: profile, dailyPlan: dailyPlans.first, progress: progress)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
