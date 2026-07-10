import SwiftUI

struct ActiveSunSessionBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            baseColor

            LinearGradient(
                colors: gradientColors,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            RadialGradient(
                colors: [
                    Color.solarGold.opacity(colorScheme == .dark ? 0.24 : 0.2),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: colorScheme == .dark ? 360 : 280
            )
        }
        .ignoresSafeArea()
    }

    private var baseColor: Color {
        colorScheme == .dark
            ? .deepSpace
            : Color(red: 0.99, green: 0.97, blue: 0.91)
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            [
                Color(red: 0.22, green: 0.16, blue: 0.1),
                .deepSpace,
                Color(red: 0.015, green: 0.035, blue: 0.07)
            ]
        } else {
            [
                Color.solarGold.opacity(0.13),
                Color(red: 1, green: 0.985, blue: 0.945),
                Color(red: 0.97, green: 0.93, blue: 0.84)
            ]
        }
    }
}
