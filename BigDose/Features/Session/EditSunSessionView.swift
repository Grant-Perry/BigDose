import SwiftData
import SwiftUI

struct EditSunSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: ExposureSession
    var profile: UserProfile

    @State private var durationMinutes: Int
    @State private var preview: SunSessionEditMetrics?

    init(session: ExposureSession, profile: UserProfile) {
        self.session = session
        self.profile = profile
        let minutes = max(1, Int((session.durationSeconds / 60).rounded()))
        _durationMinutes = State(initialValue: minutes)
    }

    private var durationSeconds: TimeInterval {
        TimeInterval(durationMinutes * 60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard
                        durationCard
                        previewCard
                        factorsCard
                    }
                    .padding(18)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Edit Sun Session")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        deleteSession()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { refreshPreview() }
            .onChange(of: durationMinutes) { _, _ in refreshPreview() }
        }
    }

    private var headerCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.solarGold)
                    .shadow(color: .solarGold.opacity(0.35), radius: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.locationLabel ?? "Sun session")
                        .font(.bigDoseHeader(.title3).weight(.semibold))
                        .foregroundStyle(.white)

                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))

                    Text("Adjust duration if you forgot to stop — IU and MED (burn risk) recalculate automatically.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.52))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var durationCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Duration")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(SunSessionDurationFormatting.timer(durationSeconds))
                    .font(.system(size: 56, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 16) {
                    adjustButton("-5", delta: -5)
                    adjustButton("-1", delta: -1)
                    Spacer()
                    adjustButton("+1", delta: 1)
                    adjustButton("+5", delta: 5)
                }

                Slider(
                    value: Binding(
                        get: { Double(durationMinutes) },
                        set: { durationMinutes = Int($0.rounded()) }
                    ),
                    in: 1...240,
                    step: 1
                )
                .tint(.solarGold)

                Text("1 min to 4 hours")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
    }

    private var previewCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Text("Updated Estimate")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let preview {
                    HStack(spacing: 12) {
                        previewPill(
                            title: "Vitamin D",
                            value: "\(Int(preview.estimatedIU.rounded()))",
                            unit: "IU",
                            tint: .solarGold
                        )

                        previewPill(
                            title: "MED Used",
                            value: "\(preview.peakMedUsedPercent)",
                            unit: "%",
                            tint: medTint(for: preview.peakMedUsedPercent)
                        )
                    }

                    HStack(spacing: 12) {
                        previewPill(
                            title: "Rate",
                            value: "\(Int(preview.iuPerMinute.rounded()))",
                            unit: "IU/min",
                            tint: .green
                        )

                        if preview.medOverLimitPercent > 0 {
                            previewPill(
                                title: "Past 100% MED",
                                value: "+\(preview.medOverLimitPercent)",
                                unit: "%",
                                tint: .gpRedPink
                            )
                        }
                    }
                }
            }
        }
    }

    private var factorsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Locked From Original Session")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))

                factorRow("UV index", session.maxUVIndex.formatted(.number.precision(.fractionLength(1))))
                factorRow("Skin exposure", "\(Int(session.exposedBodySurfaceArea * 100))%")
                factorRow("Clouds", CloudCoverPreset(rawValue: session.cloudCoverRaw)?.title ?? "Clear")
            }
        }
    }

    private func adjustButton(_ label: String, delta: Int) -> some View {
        Button {
            durationMinutes = min(240, max(1, durationMinutes + delta))
        } label: {
            Text(label)
                .font(.bigDoseHeader(.headline).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 44)
                .background(.white.opacity(0.1), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func previewPill(title: String, value: String, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(tint)
                Text(unit)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
    }

    private func factorRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private func medTint(for percent: Int) -> Color {
        switch percent {
        case 95...:
            .gpRedPink
        case 75...:
            .solarOrange
        default:
            .green
        }
    }

    private func refreshPreview() {
        preview = SunSessionEditService.metrics(
            for: session,
            profile: profile,
            durationSeconds: durationSeconds
        )
    }

    private func save() {
        SunSessionEditService.apply(
            durationSeconds: durationSeconds,
            to: session,
            profile: profile
        )
        try? modelContext.save()
        BigDoseWidgetReloader.reloadHomeWidget()
        dismiss()
    }

    private func deleteSession() {
        modelContext.delete(session)
        try? modelContext.save()
        BigDoseWidgetReloader.reloadHomeWidget()
        dismiss()
    }
}
