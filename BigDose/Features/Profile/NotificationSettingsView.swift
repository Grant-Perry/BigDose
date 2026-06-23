import SwiftData
import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
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
                    .font(.bigDoseHeader(.title3).weight(.semibold))
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
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.solarOrange, Color(red: 1.0, green: 0.58, blue: 0.14), .solarGold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .solarOrange.opacity(0.5), radius: 14, y: 6)
                    }
                    .foregroundStyle(.white)

                case .denied:
                    Text("Notifications are off in Settings. Turn them on in iOS Settings if you want BigDose reminders.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))

                default:
                    Text("BigDose schedules iOS notifications so reminders can arrive even when the app is closed. Sun session safety alerts also fire in the background during an active session.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private func alertCard(_ profile: UserProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sun & D Window")
                    .font(.bigDoseHeader(.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))

                Toggle("D window opening", isOn: binding(\.wantsDWindowOpeningAlerts))
                Toggle("D window closing", isOn: binding(\.wantsDWindowClosingAlerts))
                Toggle("Solar noon", isOn: binding(\.wantsSolarNoonAlerts))
                Toggle("Sunrise & sunset", isOn: binding(\.wantsSunriseSunsetAlerts))
                Toggle("AM light window (1°–3°)", isOn: binding(\.wantsAMLightWindowAlerts))
                Toggle("Next D window opportunity", isOn: binding(\.wantsNextDOpportunityAlerts))

                Text("Each sun alert fires 15 minutes before the event and again at the event time.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
                    .padding(.top, 2)

                Divider()
                    .overlay(.white.opacity(0.18))

                Text("Other Guidance")
                    .font(.bigDoseHeader(.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))

                Toggle("Session safety guidance", isOn: binding(\.wantsRiskAlerts))
                Toggle("Supplement reminders", isOn: binding(\.wantsSupplementReminders))
                Toggle("Lab retest reminders", isOn: binding(\.wantsLabReminders))
                Toggle("Weekly progress", isOn: binding(\.wantsWeeklyProgressAlerts))
                Toggle("Level trend notices", isOn: binding(\.wantsLevelTrendAlerts))
                Toggle("Milestones", isOn: binding(\.wantsMilestoneAlerts))
                Toggle("Weather break alerts", isOn: binding(\.wantsWeatherBreakAlerts))
            }
            .font(.bigDoseHeader(.headline).weight(.semibold))
            .foregroundStyle(.white)
            .tint(.solarGold)
        }
    }

    private func quietHoursCard(_ profile: UserProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Quiet hours", isOn: binding(\.quietHoursEnabled))
                    .font(.bigDoseHeader(.headline).weight(.semibold))
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
        profile?.syncLegacySolarAlertPreferences()
        profile?.updatedAt = .now
        try? modelContext.save()
        Task { await reschedule() }
    }

    private func reschedule() async {
        guard let profile else { return }
        await BigDoseNotificationCoordinator.refreshManagedAlerts(
            profile: profile,
            modelContext: modelContext
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
