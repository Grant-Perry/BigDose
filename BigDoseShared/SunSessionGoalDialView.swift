import SwiftUI
import UIKit

/// Goal-progress ring with the app icon at center — shared by home, widget, and Live Activity.
struct SunSessionGoalDialView: View {
    let goalProgress: Double
    let goalTimerInterval: ClosedRange<Date>?
    let isPaused: Bool
    var diameter: CGFloat = 58
    var lineWidth: CGFloat = 5
    var progressCaption: String?
    var liveProgressAnchor: Date?
    var iconOverscale: CGFloat = 1.22
    var showsNoUsefulUV = false

    private var clampedProgress: Double {
        min(max(goalProgress, 0), 1)
    }

    private var innerDiameter: CGFloat {
        diameter - lineWidth * 2
    }

    private var overlayFontSize: CGFloat {
        max(11, diameter * 0.20)
    }

    private var captionFontSize: CGFloat {
        max(8, diameter * 0.12)
    }

    var body: some View {
        ZStack {
            iconMaskedCenter

            Circle()
                .stroke(.white.opacity(0.14), lineWidth: lineWidth)

            if isPaused || goalTimerInterval == nil {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        progressRingStyle,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            } else if let interval = goalTimerInterval {
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(WidgetBrandColors.solarGold)
            }

            progressLabelOverlay
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var progressRingStyle: AnyShapeStyle {
        if showsNoUsefulUV {
            AnyShapeStyle(WidgetBrandColors.noUsefulUVGradient)
        } else {
            AnyShapeStyle(WidgetBrandColors.usefulUVGradient)
        }
    }

    private var iconMaskedCenter: some View {
        BigDoseLiveActivityLogoMark()
            .frame(
                width: innerDiameter * iconOverscale,
                height: innerDiameter * iconOverscale
            )
            .frame(width: innerDiameter, height: innerDiameter)
            .clipShape(Circle())
    }

    private var progressLabelOverlay: some View {
        Group {
            if !isPaused, let interval = goalTimerInterval {
                TimelineView(.animation(minimumInterval: 1.0, paused: false)) { timeline in
                    progressLabel(for: liveProgress(at: timeline.date, interval: interval))
                }
            } else {
                progressLabel(for: clampedProgress)
            }
        }
    }

    private func progressLabel(for progress: Double) -> some View {
        VStack(spacing: progressCaption == nil ? 0 : 1) {
            Text("\(Int(min(max(progress, 0), 1) * 100))%")
                .font(.system(size: overlayFontSize, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            if let progressCaption {
                Text(progressCaption)
                    .font(.system(size: captionFontSize, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.78), radius: 2, y: 1)
        .frame(width: innerDiameter, height: innerDiameter)
    }

    private func liveProgress(at date: Date, interval: ClosedRange<Date>) -> Double {
        let duration = interval.upperBound.timeIntervalSince(interval.lowerBound)
        guard duration > 0 else { return clampedProgress }
        let elapsed = date.timeIntervalSince(interval.lowerBound)
        return min(max(elapsed / duration, 0), 1)
    }

    private var accessibilityLabelText: String {
        if progressCaption != nil {
            "Daily sun IU goal \(Int(clampedProgress * 100)) percent complete"
        } else {
            "Session goal \(Int(clampedProgress * 100)) percent complete"
        }
    }
}

struct BigDoseLiveActivityLogoMark: View {
    var body: some View {
        Group {
            if let image = UIImage(named: "AppLogo") {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
					.offset(y: -10) 
            } else {
                Image(systemName: "sun.max.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WidgetBrandColors.solarGold)
            }
        }
        .accessibilityHidden(true)
    }
}

struct BigDoseLiveActivityLogo: View {
    var body: some View {
        BigDoseLiveActivityLogoMark()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
    }
}
