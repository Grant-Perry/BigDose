import SwiftUI

/// Full-screen launch splash. Auto-dismisses after `displayDuration`, or immediately on tap.
struct BigDoseSplashScreenView: View {
    var displayDuration: Duration = .seconds(5)
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isWordmarkVisible = false
    @State private var isTaglineVisible = false
    @State private var isHintVisible = false
    @State private var hasDismissed = false
    @State private var plasmaPhase = false

    private var hasSplashArt: Bool {
        UIImage(named: "SplashScreen") != nil
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            // Tuned to the splash art: disk center + radius in screen space.
            let sunCenterY = size.height * 0.30
            let sunRadius = min(size.width, size.height) * 0.34
            let taglineY = sunCenterY + sunRadius * 0.98

            ZStack {
                Color.black

                sunAndPlasma(in: size, sunCenterY: sunCenterY, sunRadius: sunRadius)

                // Stars sit above the opaque splash art so the universe reads.
                starField(in: size, sunCenterY: sunCenterY, sunRadius: sunRadius)

                // BIGDOSE — dead center of the solar disk.
                Text("BIGDOSE")
                    .font(.bigDoseWordmark(58))
                    .foregroundStyle(.white)
                    .tracking(-2.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.75), radius: 12, y: 4)
                    .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                    .opacity(isWordmarkVisible ? 1 : 0)
                    .scaleEffect(isWordmarkVisible ? 1 : 0.82)
                    .position(x: size.width * 0.5, y: sunCenterY)

                // Tagline sits just under the disk, into the plasma.
                BigDoseHeroTitle(
                    primaryLine: WhyBigDoseEducationContent.heroPrimaryLine,
                    accentLine: WhyBigDoseEducationContent.heroAccentLine,
                    alignment: .center,
                    primarySize: 36,
                    accentSize: 32
                )
                .padding(.horizontal, 28)
                .shadow(color: .black.opacity(0.55), radius: 8, y: 2)
                .opacity(isTaglineVisible ? 1 : 0)
                .scaleEffect(isTaglineVisible ? 1 : 0.88)
                .offset(y: isTaglineVisible ? 0 : 12)
                .position(x: size.width * 0.5, y: taglineY + 36)

                VStack {
                    Spacer()
                    bottomChrome
                }
                .frame(width: size.width, height: size.height)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("BigDose. \(WhyBigDoseEducationContent.heroPrimaryLine) \(WhyBigDoseEducationContent.heroAccentLine)")
        .accessibilityHint("Double tap to continue")
        .statusBarHidden(true)
        .onAppear {
            reveal()
            startAmbientMotion()
            scheduleAutoDismiss()
        }
    }

    // MARK: - Atmosphere

    private func starField(in size: CGSize, sunCenterY: CGFloat, sunRadius: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvasSize in
                let sunCenter = CGPoint(x: canvasSize.width * 0.5, y: sunCenterY)
                let keepOutRadius = sunRadius * 1.05

                for star in SplashStarField.stars {
                    let x = star.x * canvasSize.width
                    let y = star.y * canvasSize.height
                    let dx = x - sunCenter.x
                    let dy = y - sunCenter.y
                    // Don't paint stars on top of the solar disk.
                    guard (dx * dx + dy * dy) > (keepOutRadius * keepOutRadius) else { continue }

                    let twinkle = reduceMotion
                        ? star.baseOpacity
                        : star.baseOpacity * (0.45 + 0.55 * abs(sin(t * star.twinkleSpeed + star.phase)))
                    let rect = CGRect(
                        x: x - star.radius,
                        y: y - star.radius,
                        width: star.radius * 2,
                        height: star.radius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(twinkle)))

                    // Occasional brighter sparkle cross for larger stars.
                    if star.radius > 1.4 {
                        var spark = Path()
                        spark.move(to: CGPoint(x: x - star.radius * 1.8, y: y))
                        spark.addLine(to: CGPoint(x: x + star.radius * 1.8, y: y))
                        spark.move(to: CGPoint(x: x, y: y - star.radius * 1.8))
                        spark.addLine(to: CGPoint(x: x, y: y + star.radius * 1.8))
                        context.stroke(
                            spark,
                            with: .color(.white.opacity(twinkle * 0.55)),
                            lineWidth: 0.6
                        )
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func sunAndPlasma(in size: CGSize, sunCenterY: CGFloat, sunRadius: CGFloat) -> some View {
        ZStack {
            if hasSplashArt {
                Image("SplashScreen")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(plasmaPhase ? 1.035 : 1.0)
                    .rotationEffect(.degrees(plasmaPhase ? 2.4 : -2.4))
                    .clipped()
            }

            // Living plasma ribbons — soft rotating blooms around the disk.
            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.solarOrange.opacity(0.28 - Double(index) * 0.05),
                                Color.solarGold.opacity(0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: sunRadius * (1.15 + Double(index) * 0.18)
                        )
                    )
                    .frame(
                        width: sunRadius * (2.1 + Double(index) * 0.25),
                        height: sunRadius * (1.55 + Double(index) * 0.2)
                    )
                    .blur(radius: 18 + CGFloat(index) * 6)
                    .rotationEffect(.degrees(plasmaPhase ? Double(index + 1) * 18 : Double(index + 1) * -14))
                    .opacity(plasmaPhase ? 0.9 : 0.55)
                    .position(x: size.width * 0.5, y: sunCenterY)
            }

            yellowSunWash(diameter: sunRadius * 2)
                .position(x: size.width * 0.5, y: sunCenterY)

            // Soft lower vignette — keep stars visible in the mid/lower sky.
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private func yellowSunWash(diameter: CGFloat) -> some View {
        RadialGradient(
            colors: [
                Color(red: 1.0, green: 0.92, blue: 0.45).opacity(0.50),
                Color.solarGold.opacity(0.36),
                Color.solarOrange.opacity(0.16),
                Color.clear
            ],
            center: .center,
            startRadius: diameter * 0.06,
            endRadius: diameter * 0.52
        )
        .frame(width: diameter, height: diameter)
        .blur(radius: 10)
        .scaleEffect(plasmaPhase ? 1.04 : 0.98)
    }

    // MARK: - Chrome

    private var bottomChrome: some View {
        VStack(spacing: 16) {
            AppLogoMark(size: 52)
                .shadow(color: .solarGold.opacity(0.4), radius: 18, y: 4)
                .opacity(isTaglineVisible ? 0.95 : 0)
                .scaleEffect(isTaglineVisible ? 1 : 0.9)

            Text("Tap to dismiss")
                .font(.bigDoseBody(.caption, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .tracking(1.4)
                .textCase(.uppercase)
                .opacity(isHintVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
        .safeAreaPadding(.bottom)
    }

    // MARK: - Lifecycle

    private func reveal() {
        if reduceMotion {
            isWordmarkVisible = true
            isTaglineVisible = true
            isHintVisible = true
            return
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.78)) {
            isWordmarkVisible = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeOut(duration: 0.4)) {
                isHintVisible = true
            }

            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(.spring(response: 0.68, dampingFraction: 0.82)) {
                isTaglineVisible = true
            }
        }
    }

    private func startAmbientMotion() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
            plasmaPhase = true
        }
    }

    private func scheduleAutoDismiss() {
        Task { @MainActor in
            try? await Task.sleep(for: displayDuration)
            dismiss()
        }
    }

    private func dismiss() {
        guard !hasDismissed else { return }
        hasDismissed = true

        guard !reduceMotion else {
            onDismiss()
            return
        }

        withAnimation(.easeIn(duration: 0.28)) {
            isWordmarkVisible = false
            isTaglineVisible = false
            isHintVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            onDismiss()
        }
    }
}

// MARK: - Star field

private enum SplashStarField {
    struct Star {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var baseOpacity: Double
        var twinkleSpeed: Double
        var phase: Double
    }

    /// Deterministic field so the sky doesn't reshuffle every launch.
    static let stars: [Star] = {
        var generator = SeededGenerator(seed: 2_026_071_0)
        return (0..<160).map { index in
            let y: CGFloat
            // Heavier star density away from the sun disk.
            if index % 4 == 0 {
                y = CGFloat.random(in: 0.02...0.26, using: &generator)
            } else {
                y = CGFloat.random(in: 0.34...0.96, using: &generator)
            }
            return Star(
                x: CGFloat.random(in: 0.015...0.985, using: &generator),
                y: y,
                radius: CGFloat.random(in: 0.55...2.4, using: &generator),
                baseOpacity: Double.random(in: 0.22...0.95, using: &generator),
                twinkleSpeed: Double.random(in: 0.55...2.4, using: &generator),
                phase: Double.random(in: 0...(.pi * 2), using: &generator)
            )
        }
    }()
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEAD_BEEF : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#Preview {
    BigDoseSplashScreenView(onDismiss: {})
}
