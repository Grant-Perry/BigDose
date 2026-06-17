import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(cornerRadius: CGFloat = 30, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .bigDoseGlass(cornerRadius: cornerRadius)
    }
}

extension View {
    func bigDoseGlass(cornerRadius: CGFloat = 30) -> some View {
        modifier(BigDoseGlassModifier(cornerRadius: cornerRadius))
    }
}

private struct BigDoseGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                if reduceTransparency {
                    shape.fill(.black.opacity(0.82))
                } else {
                    shape.fill(.ultraThinMaterial.opacity(0.74))
                }
            }
            .overlay {
                shape.stroke(.glassStroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.24), radius: 24, x: 0, y: 18)
    }
}
