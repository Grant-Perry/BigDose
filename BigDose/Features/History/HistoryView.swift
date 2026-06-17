import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        summaryCard

                        if sessions.isEmpty {
                            emptyState
                        } else {
                            ForEach(sessions) { session in
                                sessionRow(session)
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Sun Ledger")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Sun, supplements, food, and labs will live here.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last 90 Days")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("\(sessions.count) sun sessions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text(totalIU.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("No sessions yet")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)

                Text("Once live tracking lands, your sun sessions will appear as clean timeline cards with UV, duration, estimated IU, and risk margin.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var totalIU: Double {
        sessions.reduce(0) { $0 + $1.estimatedIU }
    }

    private func sessionRow(_ session: ExposureSession) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.source.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text(session.startedAt, style: .time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(session.estimatedIU.rounded()))")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
