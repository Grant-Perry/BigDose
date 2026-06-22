import SwiftData
import SwiftUI

struct HistoryView: View {
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

                    Text("\(Int(todayTotalIU.rounded()))")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(.solarGold)

                    Text("IU")
                        .font(.bigDoseHeader(.headline).weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if todayTotalIU > 0 || todaySupplementIU > 0 || todayFoodIU > 0 {
                    todaySourceRow(title: "Sun", value: todaySunIU, systemImage: "sun.max.fill")
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
                } else {
                    Text("Nothing logged yet today. Sun sessions, supplements and food will show up here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))

                    todayEditableSourceRow(
                        title: "Supplements",
                        value: 0,
                        systemImage: "pills.fill",
                        emptyLabel: "Log supplement"
                    ) {
                        isShowingTodaySupplements = true
                    }

                    todayEditableSourceRow(
                        title: "Food",
                        value: 0,
                        systemImage: "fork.knife",
                        emptyLabel: "Log food"
                    ) {
                        isShowingTodayFood = true
                    }
                }
            }
        }
    }

    private func todayEditableSourceRow(
        title: String,
        value: Double,
        systemImage: String,
        emptyLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.bigDoseHeader(.subheadline).weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                if value > 0 {
                    Text("\(Int(value.rounded())) IU")
                        .font(.bigDoseHeader(.subheadline).weight(.black))
                        .foregroundStyle(.solarGold)
                } else {
                    Text(emptyLabel)
                        .font(.bigDoseHeader(.subheadline).weight(.semibold))
                        .foregroundStyle(.solarGold.opacity(0.72))
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.32))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(value > 0 ? "Edit today's \(title.lowercased())" : "Log \(title.lowercased())")
    }

    private func todaySourceRow(title: String, value: Double, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                .foregroundStyle(.white.opacity(value > 0 ? 1 : 0.42))

            Spacer()

            Text("\(Int(value.rounded())) IU")
                .font(.bigDoseHeader(.subheadline).weight(.black))
                .foregroundStyle(value > 0 ? .solarGold : .white.opacity(0.32))
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last 90 Days")
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text("\(sessions.count) sun sessions • \(supplements.count) supplement doses • \(foods.count) food entries • \(labs.count) labs")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text(totalIU.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.bigDoseHeader(.headline).weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
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

    private var todaySunIU: Double {
        sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.estimatedIU }
    }

    private var todaySupplementIU: Double {
        supplements
            .filter { calendar.isDateInToday($0.takenAt) }
            .reduce(0) { $0 + Double($1.internationalUnits) }
    }

    private var todayFoodIU: Double {
        foods
            .filter { calendar.isDateInToday($0.loggedAt) }
            .reduce(0) { $0 + Double($1.estimatedIU) }
    }

    private var todayTotalIU: Double {
        todaySunIU + todaySupplementIU + todayFoodIU
    }

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

    private func sessionRow(_ session: ExposureSession) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.historySourceTitle)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(historyTimestamp(session.startedAt))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(session.estimatedIU.rounded()))")
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
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

                    Spacer()

                    Text("\(dose.internationalUnits)")
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.solarGold)

                    Text("IU")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))

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

                    Spacer()

                    Text("\(entry.estimatedIU)")
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.solarGold)

                    Text("IU")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))

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
