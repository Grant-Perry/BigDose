import SwiftUI

/// Recessed glass progress ring for the active sun session hero dial.
struct SunSessionGlassDial: View {
    var goalProgress: Double
    var overGoalProgress: Double
    var goalProgressAtFullMED: Double
    var medUsedFraction: Double
    var goalDurationMinutes: Int
    var diameter: CGFloat = 248
    var lineWidth: CGFloat = 14
    var isPaused: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedGoldProgress = 0.0
    @State private var animatedPurpleBeforeGoal = 0.0
    @State private var animatedRedOverGoal = 0.0
    @State private var animatedPurpleOverGoal = 0.0

    private var clampedGoalProgress: Double {
        min(max(goalProgress, 0), 1)
    }

    private var clampedOverGoalProgress: Double {
        min(max(overGoalProgress, 0), 1)
    }

    private var hasPassedFullMED: Bool {
        medUsedFraction >= 1
    }

    private var totalGoalProgress: Double {
        goalProgress + overGoalProgress
    }

    /// Gold ends at the goal mark, or earlier if full MED is hit before the goal on the ring.
    private var goldRingProgress: Double {
        if hasPassedFullMED, goalProgressAtFullMED < 1 {
            return min(max(goalProgressAtFullMED, 0), 1)
        }
        return clampedGoalProgress
    }

    /// Purple on the pre-goal arc after 100% MED is reached before the IU goal mark.
    private var purpleBeforeGoalLength: Double {
        guard hasPassedFullMED, goalProgressAtFullMED < 1 else { return 0 }
        return min(max(totalGoalProgress - goalProgressAtFullMED, 0), 1 - goalProgressAtFullMED)
    }

    /// Red over-goal segment — only the portion still under 100% MED.
    private var redOverGoalLength: Double {
        guard clampedOverGoalProgress > 0 else { return 0 }
        if goalProgressAtFullMED >= totalGoalProgress { return clampedOverGoalProgress }
        if goalProgressAtFullMED <= 1 { return 0 }
        return min(goalProgressAtFullMED - 1, clampedOverGoalProgress)
    }

    /// Purple over-goal segment — everything past 100% MED on the ring.
    private var purpleOverGoalLength: Double {
        guard clampedOverGoalProgress > 0 else { return 0 }
        if goalProgressAtFullMED >= totalGoalProgress { return 0 }
        if goalProgressAtFullMED <= 1 { return clampedOverGoalProgress }
        return max(0, totalGoalProgress - goalProgressAtFullMED)
    }

    private var tickMinuteCount: Int {
        max(1, goalDurationMinutes)
    }

    var body: some View {
        ZStack {
            glassPlate
            trackRing
            minuteTicks
            progressGlow
            goalProgressRing
            if animatedPurpleBeforeGoal > 0 {
                purpleBeforeGoalRing
            }
            if animatedRedOverGoal > 0 {
                redOverGoalProgressRing
            }
            if animatedPurpleOverGoal > 0 {
                purpleOverGoalProgressRing
            }
            specularHighlight
        }
        .frame(width: diameter + 36, height: diameter + 36)
        .opacity(isPaused ? 0.72 : 1)
        .animation(.smooth(duration: 0.35), value: isPaused)
        .onAppear { animateProgress() }
        .onChange(of: goalProgress) { animateProgress() }
        .onChange(of: overGoalProgress) { animateProgress() }
        .onChange(of: goalProgressAtFullMED) { animateProgress() }
        .onChange(of: medUsedFraction) { animateProgress() }
        .accessibilityHidden(true)
    }

    private var glassPlate: some View {
        Circle()
            .fill(plateFill)
            .frame(width: diameter + 28, height: diameter + 28)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.28), radius: 28, y: 14)
    }

    private var plateFill: some ShapeStyle {
        if reduceTransparency {
            AnyShapeStyle(Color.black.opacity(0.55))
        } else {
            AnyShapeStyle(.ultraThinMaterial.opacity(0.62))
        }
    }

    private var trackRing: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: diameter, height: diameter)

            Circle()
                .stroke(Color.black.opacity(0.65), lineWidth: lineWidth * 0.75)
                .blur(radius: 3)
                .offset(y: 2)
                .frame(width: diameter, height: diameter)
                .mask {
                    Circle()
                        .stroke(lineWidth: lineWidth)
                        .frame(width: diameter, height: diameter)
                }

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .padding(lineWidth / 2 + 1)
                .frame(width: diameter, height: diameter)
        }
    }

    private var minuteTicks: some View {
        ZStack {
            ForEach(1..<tickMinuteCount, id: \.self) { minute in
                dialTick(
                    at: Double(minute) / Double(tickMinuteCount),
                    isMajor: minute.isMultiple(of: 5)
                )
            }

            dialTick(at: 0, isMajor: true)
        }
        .frame(width: diameter, height: diameter)
    }

    private func dialTick(at fraction: Double, isMajor: Bool) -> some View {
        Capsule()
            .fill(Color.white.opacity(isMajor ? 0.34 : 0.16))
            .frame(width: isMajor ? 2 : 1, height: lineWidth + (isMajor ? 8 : 5))
            .offset(y: -(diameter / 2))
            .rotationEffect(.degrees((fraction * 360) - 90))
    }

    private var progressGlow: some View {
        Circle()
            .trim(from: 0, to: animatedGoldProgress)
            .stroke(Color.solarGold.opacity(0.42), lineWidth: lineWidth + 10)
            .blur(radius: 14)
            .rotationEffect(.degrees(-90))
            .frame(width: diameter, height: diameter)
    }

    private var goalProgressRing: some View {
        Circle()
            .trim(from: 0, to: animatedGoldProgress)
            .stroke(
                AngularGradient(
                    colors: [.solarOrange, .solarGold, .solarOrange],
                    center: .center,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: .solarGold.opacity(0.45), radius: 8)
            .frame(width: diameter, height: diameter)
    }

    private var purpleBeforeGoalRing: some View {
        Circle()
            .trim(from: 0, to: animatedPurpleBeforeGoal)
            .stroke(
                purpleRingGradient,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90 + (360 * min(max(goalProgressAtFullMED, 0), 1))))
            .shadow(color: .gpDeltaPurple.opacity(0.42), radius: 8)
            .frame(width: diameter, height: diameter)
    }

    private var redOverGoalProgressRing: some View {
        Circle()
            .trim(from: 0, to: animatedRedOverGoal)
            .stroke(
                LinearGradient(
                    colors: [.gpRedPink, .red],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90 + (360 * animatedGoldProgress)))
            .shadow(color: .gpRedPink.opacity(0.4), radius: 8)
            .frame(width: diameter, height: diameter)
    }

    private var purpleOverGoalProgressRing: some View {
        Circle()
            .trim(from: 0, to: animatedPurpleOverGoal)
            .stroke(
                purpleRingGradient,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90 + (360 * (animatedGoldProgress + animatedRedOverGoal))))
            .shadow(color: .gpDeltaPurple.opacity(0.42), radius: 8)
            .frame(width: diameter, height: diameter)
    }

    private var purpleRingGradient: LinearGradient {
        LinearGradient(
            colors: [.gpDeltaPurple, .purple],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    private var specularHighlight: some View {
        Circle()
            .trim(from: 0.08, to: 0.22)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.35), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: diameter - lineWidth, height: diameter - lineWidth)
            .blendMode(.plusLighter)
    }

    private func animateProgress() {
        if reduceMotion {
            animatedGoldProgress = goldRingProgress
            animatedPurpleBeforeGoal = purpleBeforeGoalLength
            animatedRedOverGoal = redOverGoalLength
            animatedPurpleOverGoal = purpleOverGoalLength
            return
        }

        withAnimation(.smooth(duration: 0.85)) {
            animatedGoldProgress = goldRingProgress
            animatedPurpleBeforeGoal = purpleBeforeGoalLength
            animatedRedOverGoal = redOverGoalLength
            animatedPurpleOverGoal = purpleOverGoalLength
        }
    }
}
