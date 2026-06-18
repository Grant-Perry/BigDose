import SwiftData
import SwiftUI

struct HealthImportBatchLogView: View {
    let batchImportedAt: Date

    @Query private var items: [HealthImportItem]

    init(batchImportedAt: Date) {
        self.batchImportedAt = batchImportedAt
        _items = Query(
            filter: #Predicate<HealthImportItem> { $0.batchImportedAt == batchImportedAt },
            sort: \HealthImportItem.startedAt,
            order: .reverse
        )
    }

    private var acceptedItems: [HealthImportItem] {
        items.filter(\.wasAcceptedForExposure)
    }

    private var skippedItems: [HealthImportItem] {
        items.filter { !$0.wasAcceptedForExposure }
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    summaryCard

                    if !acceptedItems.isEmpty {
                        sectionHeader("Accepted", count: acceptedItems.count, systemImage: "checkmark.circle.fill", tint: .green)
                        ForEach(acceptedItems, id: \.persistentModelID) { item in
                            itemRow(item)
                        }
                    }

                    if !skippedItems.isEmpty {
                        sectionHeader("Skipped", count: skippedItems.count, systemImage: "minus.circle.fill", tint: .white.opacity(0.5))
                        ForEach(skippedItems, id: \.persistentModelID) { item in
                            itemRow(item)
                        }
                    }

                    if items.isEmpty {
                        GlassCard {
                            Text("No import items were recorded for this batch.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Import Log")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Import Log")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text(batchImportedAt.formatted(date: .complete, time: .shortened))
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(acceptedItems.count) accepted")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("\(skippedItems.count) skipped")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(items.count)")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("items")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.caption.weight(.black))
                .tracking(1.6)
                .foregroundStyle(tint)

            Text("\(count)")
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func itemRow(_ item: HealthImportItem) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.activityName)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)

                        Text(item.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Text("\(Int(item.durationSeconds / 60)) min")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.solarGold)
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Label(
                    item.wasAcceptedForExposure ? "Imported as sun exposure" : "Not imported",
                    systemImage: item.wasAcceptedForExposure ? "sun.max.fill" : "minus.circle"
                )
                .font(.caption.weight(.black))
                .foregroundStyle(item.wasAcceptedForExposure ? .solarOrange : .white.opacity(0.5))
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthImportBatchLogView(batchImportedAt: .now)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
