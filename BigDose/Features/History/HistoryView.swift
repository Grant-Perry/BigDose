import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    @Query(sort: \HealthImportBatch.importedAt, order: .reverse) private var importBatches: [HealthImportBatch]
    @State private var isShowingTodaySupplements = false
    @State private var isShowingTodayFood = false
    @State private var editingSupplement: SupplementDose?
    @State private var editingFood: FoodVitaminDEntry?
    @State private var editingSunSession: ExposureSession?
    @State private var healthKitImportService = HealthKitImportService()
    @State private var isRefreshingAppleHealth = false

    private var calendar: Calendar { .current }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        todayLedgerCard
                        summaryCard

                        if sessions.isEmpty && supplements.isEmpty && foods.isEmpty && labs.isEmpty && importBatches.isEmpty {
                            emptyState
                        } else {
                            sectionTitle("Sun")
                            ForEach(sessions) { session in
                                sessionRow(session)
                            }

                            sectionTitle("Supplements")
                            ForEach(supplements) { dose in
                                supplementRow(dose)
                            }

                            sectionTitle("Food")
                            ForEach(foods) { entry in
                                foodRow(entry)
                            }

                            sectionTitle("Labs")
                            ForEach(labs) { result in
                                labRow(result)
                            }

                            sectionTitle("Imports")
                            ForEach(importBatches) { batch in
                                NavigationLink {
                                    HealthImportBatchLogView(batchImportedAt: batch.importedAt)
                                } label: {
                                    importRow(batch)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("History")
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingTodaySupplements) {
                DailySupplementLedgerSheet(profile: profile)
            }
            .sheet(isPresented: $isShowingTodayFood) {
                DailyFoodLedgerSheet()
            }
            .sheet(item: $editingSupplement) { dose in
                AddSupplementDoseView(profile: profile, dose: dose)
            }
            .sheet(item: $editingFood) { entry in
                FoodVitaminDEntryEditorView(entry: entry)
            }
            .sheet(item: $editingSunSession) { session in
                EditSunSessionView(session: session, profile: profile ?? .preview)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Sun Ledger")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Sun, supplements, food and labs in one place.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var todayLedgerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Today")
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Spacer()

                    historyIUValue(
                        value: todayTotalIU,
                        numberFont: .system(size: 42, weight: .black),
                        unitFont: .bigDoseHeader(.headline).weight(.bold)
                    )
                }

                if todayTotalIU > 0 {
                    Text(todayTotalBreakdownCaption)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if todayTotalIU == 0 {
                    Text("Nothing logged yet today. Sun sessions, supplements and food will show up here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }

                VStack(alignment: .leading, spacing: 6) {
                    todaySunComponentRow(
                        title: "Tracked / Exposure",
                        systemImage: "sun.max.fill",
                        value: todaySunBreakdown.trackedIU,
                        showsEstimatePrefix: false,
                        titleOpacity: todaySunBreakdown.trackedIU > 0 ? 0.82 : 0.42
                    )

                    todaySunComponentRow(
                        title: "Incidental",
                        systemImage: "sun.horizon.fill",
                        value: todaySunBreakdown.incidentalIU,
                        showsEstimatePrefix: true,
                        titleOpacity: todaySunBreakdown.incidentalIU > 0 ? 0.82 : 0.42,
                        infoTopic: .incidentalDaylight,
                        showsAppleHealthRefresh: profile?.wantsHealthKitSync == true
                    )

                    todaySunComponentRow(
                        title: "Imported",
                        systemImage: "figure.walk",
                        value: todaySunBreakdown.importedIU,
                        showsEstimatePrefix: true,
                        titleOpacity: todaySunBreakdown.importedIU > 0 ? 0.82 : 0.42,
                        infoTopic: .importedSun
                    )

                    Divider()
                        .overlay(.white.opacity(0.12))
                        .padding(.vertical, 2)

                    todaySunTotalRow(value: todaySunIU)

                    if todayMedExcessSeconds > 0 {
                        todayMedExcessRow(seconds: todayMedExcessSeconds)
                    }
                }

                todayEditableSourceRow(
                    title: "Supplements",
                    value: todaySupplementIU,
                    systemImage: "pills.fill",
                    emptyLabel: "Log supplement"
                ) {
                    isShowingTodaySupplements = true
                }

                todayEditableSourceRow(
                    title: "Food",
                    value: todayFoodIU,
                    systemImage: "fork.knife",
                    emptyLabel: "Log food"
                ) {
                    isShowingTodayFood = true
                }
            }
        }
    }

    private enum TodayLedgerLayout {
        static let iconWidth: CGFloat = 22
        static let rowSpacing: CGFloat = 10
        static let valueWidth: CGFloat = 92
        static let accessoryWidth: CGFloat = 14
        static let rowMinHeight: CGFloat = 28
    }

    private func todayEditableSourceRow(
        title: String,
        value: Double,
        systemImage: String,
        emptyLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: TodayLedgerLayout.rowSpacing) {
                todayLedgerIcon(systemImage, opacity: value > 0 ? 1 : 0.42)

                Text(title)
                    .font(.bigDoseHeader(.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(value > 0 ? 1 : 0.42))

                Spacer(minLength: 0)

                Group {
                    if value > 0 {
                        historyIUValue(value: value)
                    } else {
                        Text(emptyLabel)
                            .font(.bigDoseHeader(.subheadline).weight(.semibold))
                            .foregroundStyle(.solarGold.opacity(0.72))
                            .multilineTextAlignment(.trailing)
                    }
                }
                .frame(minWidth: TodayLedgerLayout.valueWidth, alignment: .trailing)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.32))
                    .frame(width: TodayLedgerLayout.accessoryWidth, alignment: .trailing)
            }
            .frame(minHeight: TodayLedgerLayout.rowMinHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(value > 0 ? "Edit today's \(title.lowercased())" : "Log \(title.lowercased())")
    }

    private var todayMedExcessSeconds: TimeInterval { todayIUIntake.medExcessSeconds }

    private func todayMedExcessRow(seconds: TimeInterval) -> some View {
        HStack(alignment: .center, spacing: TodayLedgerLayout.rowSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.gpDeltaPurple)
                .frame(width: TodayLedgerLayout.iconWidth, height: TodayLedgerLayout.rowMinHeight, alignment: .center)

            Text("Past 100% MED")
                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            Spacer(minLength: 0)

            Text(SunSessionDurationFormatting.compact(seconds))
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Color.gpDeltaPurple)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: TodayLedgerLayout.valueWidth, alignment: .trailing)

            Color.clear
                .frame(width: TodayLedgerLayout.accessoryWidth)
        }
        .frame(minHeight: TodayLedgerLayout.rowMinHeight)
        .accessibilityLabel("Past 100% MED excess time \(SunSessionDurationFormatting.compact(seconds))")
    }

    private func todaySunTotalRow(value: Double) -> some View {
        HStack(alignment: .center, spacing: TodayLedgerLayout.rowSpacing) {
            Image(systemName: "sun.max.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.solarGold)
                .frame(width: TodayLedgerLayout.iconWidth, height: 34, alignment: .center)

            Text("Sun")
                .font(.bigDoseHeader(.headline).weight(.black))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            historyIUValue(
                value: value,
                numberFont: .system(size: 26, weight: .black),
                unitFont: .bigDoseHeader(.subheadline).weight(.bold)
            )
            .frame(width: TodayLedgerLayout.valueWidth, alignment: .trailing)

            Color.clear
                .frame(width: TodayLedgerLayout.accessoryWidth)
        }
        .frame(minHeight: 34)
        .padding(.top, 2)
    }

    private func todaySunComponentRow(
        title: String,
        systemImage: String,
        value: Double,
        showsEstimatePrefix: Bool,
        titleOpacity: Double,
        infoTopic: BigDoseInfoTopic? = nil,
        showsAppleHealthRefresh: Bool = false
    ) -> some View {
        HStack(alignment: .center, spacing: TodayLedgerLayout.rowSpacing) {
            todayLedgerIcon(systemImage, opacity: titleOpacity)

            HStack(spacing: 4) {
                Text(title)
                    .font(.bigDoseHeader(.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(titleOpacity))

                if let infoTopic {
                    InfoCircleButton(topic: infoTopic, iconSize: 11, compact: true)
                }

                if showsAppleHealthRefresh {
                    AppleHealthRefreshButton(isRefreshing: isRefreshingAppleHealth) {
                        Task { await refreshAppleHealth() }
                    }
                }
            }

            Spacer(minLength: 0)

            historyIUValue(
                value: value,
                showsEstimatePrefix: showsEstimatePrefix,
                numberUsesSecondary: true
            )
            .frame(width: TodayLedgerLayout.valueWidth, alignment: .trailing)

            Color.clear
                .frame(width: TodayLedgerLayout.accessoryWidth)
        }
        .frame(minHeight: TodayLedgerLayout.rowMinHeight)
    }

    private var todayTotalBreakdownCaption: String {
        var parts: [String] = []
        if todaySunIU > 0 {
            parts.append("sun \(Int(todaySunIU.rounded()))")
        }
        if todaySupplementIU > 0 {
            parts.append("supplements \(Int(todaySupplementIU.rounded()))")
        }
        if todayFoodIU > 0 {
            parts.append("food \(Int(todayFoodIU.rounded()))")
        }
        guard !parts.isEmpty else { return "" }
        return parts.joined(separator: " + ")
    }

    private func refreshAppleHealth() async {
        guard let profile, profile.wantsHealthKitSync else { return }
        guard !isRefreshingAppleHealth else { return }

        isRefreshingAppleHealth = true
        defer { isRefreshingAppleHealth = false }

        await healthKitImportService.silentRefreshIfNeeded(
            profile: profile,
            modelContext: modelContext,
            force: true
        )
    }

    private func todayLedgerIcon(_ systemImage: String, opacity: Double) -> some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.solarGold.opacity(opacity))
            .frame(width: TodayLedgerLayout.iconWidth, height: TodayLedgerLayout.rowMinHeight, alignment: .center)
    }

    private func historyIUValue(
        value: Double,
        showsEstimatePrefix: Bool = false,
        numberFont: Font = .bigDoseHeader(.subheadline).weight(.black),
        unitFont: Font = .bigDoseHeader(.caption).weight(.bold),
        numberUsesSecondary: Bool = false
    ) -> some View {
        let numberColor: Color = numberUsesSecondary
            ? .secondary
            : (value > 0 ? .solarGold : .white.opacity(0.32))

        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            HStack(spacing: 0) {
                Text("~")
                    .font(numberFont)
                    .foregroundStyle(numberColor)
                    .opacity(showsEstimatePrefix ? 1 : 0)
                    .frame(width: 10, alignment: .leading)

                Text("\(Int(value.rounded()))")
                    .font(numberFont)
                    .monospacedDigit()
                    .foregroundStyle(numberColor)
            }

            Text("IU")
                .font(unitFont)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Last 90 Days")
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Spacer(minLength: 8)

                    historyIUValue(
                        value: totalIU,
                        numberFont: .system(size: 42, weight: .black),
                        unitFont: .bigDoseHeader(.headline).weight(.bold)
                    )
                    .layoutPriority(1)
                }

                Text("\(sessions.count) sun sessions • \(supplements.count) supplement doses • \(foods.count) food entries • \(labs.count) labs")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.bigDoseHeader(.largeTitle).weight(.black))
                    .foregroundStyle(.solarGold)

                Text("No sessions yet")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.white)

                Text("Once live tracking lands, your sun sessions will appear as clean timeline cards with UV, duration, estimated IU and risk margin.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var totalIU: Double {
        sessions.reduce(0) { $0 + $1.estimatedIU }
            + supplements.reduce(0) { $0 + Double($1.internationalUnits) }
            + foods.reduce(0) { $0 + Double($1.estimatedIU) }
    }

    private var todayIUIntake: DailyIUIntakeSummary {
        DailyIUIntakeAggregation.today(
            sessions: sessions,
            supplements: supplements,
            foods: foods,
            calendar: calendar
        )
    }

    private var todaySunIU: Double { todayIUIntake.sunIU }
    private var todaySunBreakdown: TodaySunBreakdown { todayIUIntake.sunBreakdown }
    private var todaySupplementIU: Double { todayIUIntake.supplementIU }
    private var todayFoodIU: Double { todayIUIntake.foodIU }
    private var todayTotalIU: Double { todayIUIntake.totalIU }

    private func historyTimestamp(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.black))
            .tracking(1.6)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 4)
    }

    @ViewBuilder
    private func sessionRow(_ session: ExposureSession) -> some View {
        let content = GlassCard(cornerRadius: 24) {
            HStack(alignment: .top) {
                Image(systemName: session.source == .healthKitDaylight ? "sun.horizon.fill" : "sun.max.fill")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(session.historySourceTitle)
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)

                        if session.source == .healthKitDaylight, profile?.wantsHealthKitSync == true {
                            AppleHealthRefreshButton(isRefreshing: isRefreshingAppleHealth) {
                                Task { await refreshAppleHealth() }
                            }
                        }
                    }

                    if let subtitle = session.historySubtitle ?? session.trackedSessionDetail {
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.52))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(session.historyTimestamp(calendar: calendar))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer(minLength: 0)

                historyIUValue(
                    value: session.estimatedIU,
                    showsEstimatePrefix: session.showsHolickEstimate,
                    numberFont: .bigDoseHeader(.title2).weight(.black),
                    unitFont: .caption.weight(.bold)
                )

                if SunSessionEditService.isEditable(session) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.32))
                        .padding(.top, 6)
                }
            }
        }

        if SunSessionEditService.isEditable(session) {
            Button {
                editingSunSession = session
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private func supplementRow(_ dose: SupplementDose) -> some View {
        Button {
            editingSupplement = dose
        } label: {
            GlassCard(cornerRadius: 24) {
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Supplement")
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)

                        Text(historyTimestamp(dose.takenAt))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer(minLength: 0)

                    historyIUValue(
                        value: Double(dose.internationalUnits),
                        numberFont: .bigDoseHeader(.title2).weight(.black),
                        unitFont: .caption.weight(.bold)
                    )

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func foodRow(_ entry: FoodVitaminDEntry) -> some View {
        Button {
            editingFood = entry
        } label: {
            GlassCard(cornerRadius: 24) {
                HStack {
                    Image(systemName: "fork.knife")
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.foodName.isEmpty ? "Food" : entry.foodName)
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)

                        Text(historyTimestamp(entry.loggedAt))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer(minLength: 0)

                    historyIUValue(
                        value: Double(entry.estimatedIU),
                        numberFont: .bigDoseHeader(.title2).weight(.black),
                        unitFont: .caption.weight(.bold)
                    )

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func labRow(_ result: LabResult) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "testtube.2")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("25(OH)D Result")
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(result.measuredAt, style: .date)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(result.nanogramsPerMilliliter.rounded()))")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)

                Text("ng/mL")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func importRow(_ batch: HealthImportBatch) -> some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Image("WorksWithAppleHealth")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180, maxHeight: 28, alignment: .leading)
                    .accessibilityHidden(true)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Health Import")
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)

                        Text("\(batch.workoutCount) workouts • \(batch.acceptedExposureCount) accepted")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        if batch.daylightDayCount > 0 {
                            Text("\(batch.daylightDayCount) daylight days")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                    }

                    Spacer()

                    Text(batch.importedAt, style: .date)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Apple Health import on \(batch.importedAt.formatted(date: .abbreviated, time: .omitted)). \(batch.workoutCount) workouts, \(batch.acceptedExposureCount) accepted.")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
