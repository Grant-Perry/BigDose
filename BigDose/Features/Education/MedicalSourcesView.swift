import SwiftUI

struct MedicalSourcesView: View {
    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    GlassCard(cornerRadius: 26) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Why these links exist", systemImage: "doc.text.magnifyingglass")
                                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                                .foregroundStyle(.solarGold)

                            Text("BigDose shows wellness guidance based on published vitamin D, UV and sun-safety research. These external sources explain the science behind intake targets, burn-risk estimates, UV timing and lab testing.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    ForEach(Array(BigDoseMedicalSourceCatalog.groupedSections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))

                            ForEach(section.sourceIDs, id: \.self) { sourceID in
                                sourceCard(BigDoseMedicalSourceCatalog.source(for: sourceID))
                            }
                        }
                    }

                    Text("BigDose is informational wellness guidance. It does not diagnose deficiency, prescribe treatment or replace a clinician or 25(OH)D blood test.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.52))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Sources")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Information Sources")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Tap any citation to open the original reference in Safari.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private func sourceCard(_ source: BigDoseMedicalSource) -> some View {
        Link(destination: source.url) {
            GlassCard(cornerRadius: 24) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.bigDoseHeader(.title2).weight(.semibold))
                        .foregroundStyle(.solarGold)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(source.title)
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Text(source.summary)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MedicalSourcesView()
    }
}
