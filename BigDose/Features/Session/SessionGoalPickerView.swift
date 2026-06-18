import SwiftUI

struct SessionGoalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var targetIU: Double

    private let presets = [600, 1_000, 2_000, 4_000, 5_000]

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                VStack(alignment: .leading, spacing: 14) {
                    Text("\(Int(targetIU.rounded())) IU")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.solarGold)

                    Text("Session goal")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(presets, id: \.self) { iu in
                            Button {
                                withAnimation(.smooth) {
                                    targetIU = Double(iu)
                                }
                            } label: {
                                Text("\(iu.formatted()) IU")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(Int(targetIU.rounded()) == iu ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        Int(targetIU.rounded()) == iu ? Color.solarGold : .white.opacity(0.08),
                                        in: .rect(cornerRadius: 14)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Session Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.solarGold)
                }
            }
        }
    }
}
