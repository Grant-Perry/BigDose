import SwiftUI

struct BigDoseGradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAwake = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.gpDarkL,
                    Color.gpDark2,
                    Color.gpDark1,
                    Color.gpDesignGold.opacity(0.24)
                ],
                startPoint: isAwake ? .topLeading : .topTrailing,
                endPoint: isAwake ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.gpDesignGold.opacity(0.24))
                .blur(radius: 70)
                .frame(width: 260, height: 260)
                .offset(x: isAwake ? 130 : -90, y: isAwake ? -260 : -180)

            Circle()
                .fill(Color.gpOrange.opacity(0.14))
                .blur(radius: 90)
                .frame(width: 320, height: 320)
                .offset(x: isAwake ? -150 : 120, y: 260)
        }
        .onAppear {
            guard !reduceMotion else {
                isAwake = true
                return
            }
            withAnimation(.easeInOut(duration: 2.8)) {
                isAwake = true
            }
        }
    }
}
