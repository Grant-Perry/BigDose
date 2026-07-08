import SwiftUI

struct InfoCircleButton: View {
    var topic: BigDoseInfoTopic
    var iconSize: CGFloat = 18
    var compact: Bool = false
    var helpText: String?

    @State private var isPresented = false

    private var circleDiameter: CGFloat {
        compact ? 16 : 18
    }

    private var tapTarget: CGFloat {
        compact ? 28 : 32
    }

    private var glyphFont: Font {
        let scale = compact ? 0.48 : 0.5
        let size = min(iconSize * scale, compact ? 8 : 9)
        return .system(size: size, weight: .bold, design: .rounded)
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            ZStack {
                SiriGlyph(systemName: "info", font: glyphFont)
            }
            .frame(width: circleDiameter, height: circleDiameter)
            .background {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.35))
            }
            .siriBorder(
                cornerRadius: circleDiameter / 2,
                lineWidth: compact ? 1.25 : 1.5,
                glowBlur: compact ? 1.5 : 2,
                glowOpacity: 0.72
            )
            .frame(width: tapTarget, height: tapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(helpText ?? "View \(topic.title) info")
        .popover(isPresented: $isPresented) {
            InfoBoxView(
                title: topic.title,
                bodyText: topic.bodyText,
                sources: topic.sources,
                onClose: { isPresented = false }
            )
            .padding(12)
            .presentationCompactAdaptation(.popover)
        }
    }
}
