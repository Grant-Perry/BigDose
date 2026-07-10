import SwiftUI

/// Bottom of the splash sun + plasma rays baking down from the top edge.
struct BigDoseSolarCrestView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var plasmaPhase = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Disk is larger than the crest so most of it sits above the top edge.
            let sunSize = width * 1.35

            ZStack {
                // Hard sun limb — always visible even if art crop fails.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.55),
                                Color.solarGold,
                                Color.solarOrange,
                                Color.solarOrange.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: sunSize * 0.05,
                            endRadius: sunSize * 0.52
                        )
                    )
                    .frame(width: sunSize, height: sunSize)
                    .blur(radius: 1.5)
                    .scaleEffect(plasmaPhase ? 1.03 : 1.0)
                    // Center sits above the crest; only the lower arc peeks in.
                    .position(x: width * 0.5, y: -(sunSize * 0.28))

                if UIImage(named: "SplashScreen") != nil {
                    // Top-align the tall splash art so we keep the sun/plasma,
                    // then pull it up until only the lower limb + rays remain.
                    Image("SplashScreen")
                        .resizable()
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .frame(width: width * 1.55)
                        .scaleEffect(plasmaPhase ? 1.04 : 1.0)
                        .rotationEffect(.degrees(plasmaPhase ? 1.8 : -1.8))
                        .frame(width: width, height: height * 2.4, alignment: .top)
                        .offset(y: -(height * 1.15))
                        .blendMode(.screen)
                        .opacity(0.95)
                        .frame(width: width, height: height, alignment: .top)
                        .clipped()
                }

                // Drifting plasma blooms under the limb.
                ForEach(0..<4, id: \.self) { index in
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.solarOrange.opacity(0.42 - Double(index) * 0.06),
                                    Color.solarGold.opacity(0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: width * (0.22 + Double(index) * 0.07)
                            )
                        )
                        .frame(
                            width: width * (0.55 + Double(index) * 0.14),
                            height: height * (0.55 + Double(index) * 0.12)
                        )
                        .blur(radius: 12 + CGFloat(index) * 5)
                        .rotationEffect(.degrees(plasmaPhase ? Double(index + 1) * 14 : Double(index + 1) * -12))
                        .opacity(plasmaPhase ? 0.95 : 0.55)
                        .offset(
                            x: index.isMultiple(of: 2) ? width * 0.04 : -width * 0.05,
                            y: height * (0.08 + Double(index) * 0.06)
                        )
                }

                // Soft corona wash from the top edge downward.
                LinearGradient(
                    colors: [
                        Color.solarGold.opacity(0.55),
                        Color.solarOrange.opacity(0.28),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 8)
                .scaleEffect(y: plasmaPhase ? 1.08 : 0.94, anchor: .top)

                // Fade into the dashboard — keep the top hot, bottom readable.
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.35),
                        Color.black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: width, height: height)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                plasmaPhase = true
            }
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color.black.ignoresSafeArea()
        BigDoseSolarCrestView()
            .frame(height: 260)
            .ignoresSafeArea(edges: .top)
        Text("DASHBOARD")
            .font(.bigDoseHeader(.title2).weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 140)
    }
}
