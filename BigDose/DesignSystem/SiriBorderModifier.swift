import SwiftUI

enum SiriStyle {
    static let gradientColors: [Color] = [
        .blue, .cyan, .green, .yellow, .orange,
        Color(red: 0.9, green: 0.4, blue: 0.5),
        .purple, .blue
    ]

    static let rotationDuration: TimeInterval = 3
}

struct SiriBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let glowBlur: CGFloat
    let glowOpacity: Double
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(angularGradient, lineWidth: lineWidth)
                    .blur(radius: glowBlur)
                    .opacity(glowOpacity)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(angularGradient, lineWidth: lineWidth)
            }
            .onAppear { startRotation() }
    }

    private var angularGradient: AngularGradient {
        AngularGradient(
            colors: SiriStyle.gradientColors,
            center: .center,
            startAngle: .degrees(rotation),
            endAngle: .degrees(rotation + 360)
        )
    }

    private func startRotation() {
        withAnimation(.linear(duration: SiriStyle.rotationDuration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

struct SiriGlyph: View {
    let systemName: String
    var font: Font = .system(size: 9, weight: .bold, design: .rounded)

    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: systemName)
            .font(font)
            .foregroundStyle(
                AngularGradient(
                    colors: SiriStyle.gradientColors,
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: SiriStyle.rotationDuration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func siriBorder(
        cornerRadius: CGFloat = 24,
        lineWidth: CGFloat = 8,
        glowBlur: CGFloat = 6,
        glowOpacity: Double = 0.85
    ) -> some View {
        modifier(
            SiriBorderModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                glowBlur: glowBlur,
                glowOpacity: glowOpacity
            )
        )
    }
}
