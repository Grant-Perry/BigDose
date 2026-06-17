import SwiftUI

struct SkinExposurePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exposedBodySurfaceArea: Double

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(exposedBodySurfaceArea * 100))")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.solarGold)
                        Text("% exposed")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Slider(value: $exposedBodySurfaceArea, in: 0.05...0.85, step: 0.05)
                        .tint(.solarGold)

                    VStack(spacing: 10) {
                        ForEach(SkinExposurePreset.allCases) { preset in
                            Button {
                                withAnimation(.smooth) {
                                    exposedBodySurfaceArea = preset.exposedBodySurfaceArea
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(preset.title)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(preset.detail)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.58))
                                    }

                                    Spacer()

                                    Text("\(Int(preset.exposedBodySurfaceArea * 100))%")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.solarGold)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            if preset != SkinExposurePreset.allCases.last {
                                Divider().overlay(.white.opacity(0.12))
                            }
                        }
                    }
                    .padding(18)
                    .bigDoseGlass(cornerRadius: 28)

                    Spacer()
                }
                .padding(22)
            }
            .navigationTitle("Skin Exposure")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.solarGold)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.solarGold)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var exposure = 0.25
    SkinExposurePickerView(exposedBodySurfaceArea: $exposure)
}
