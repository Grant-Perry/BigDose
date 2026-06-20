import SwiftUI

/// Renders compact duration notation with de-emphasized unit suffixes (`9h 13m`).
struct BigDoseDurationText: View {
    var components: BigDoseDurationComponents
    var font: Font
    var valueColor: Color
    var unitColor: Color?

    init(
        _ components: BigDoseDurationComponents,
        font: Font = .system(size: 34, weight: .black),
        valueColor: Color = .primary,
        unitColor: Color? = nil
    ) {
        self.components = components
        self.font = font
        self.valueColor = valueColor
        self.unitColor = unitColor
    }

    init(
        minutes: Int,
        font: Font = .system(size: 34, weight: .black),
        valueColor: Color = .primary,
        unitColor: Color? = nil
    ) {
        self.init(
            BigDoseDurationComponents(minutes: minutes),
            font: font,
            valueColor: valueColor,
            unitColor: unitColor
        )
    }

    init(
        duration: TimeInterval,
        font: Font = .system(size: 34, weight: .black),
        valueColor: Color = .primary,
        unitColor: Color? = nil
    ) {
        self.init(
            BigDoseDurationComponents(duration: duration),
            font: font,
            valueColor: valueColor,
            unitColor: unitColor
        )
    }

    var body: some View {
        styledText
            .accessibilityLabel(components.accessibilityLabel)
    }

    @ViewBuilder
    private var styledText: some View {
        let unitForeground = unitColor ?? valueColor.opacity(BigDoseDurationStyle.unitOpacity)

        if components.hours > 0, components.minutes > 0 {
            HStack(spacing: 0) {
                valueText(components.hours)
                unitText(BigDoseDurationStyle.hourSuffix, color: unitForeground)
                Text(BigDoseDurationStyle.componentSpacing)
                valueText(components.minutes)
                unitText(BigDoseDurationStyle.minuteSuffix, color: unitForeground)
            }
        } else if components.hours > 0 {
            HStack(spacing: 0) {
                valueText(components.hours)
                unitText(BigDoseDurationStyle.hourSuffix, color: unitForeground)
            }
        } else {
            HStack(spacing: 0) {
                valueText(components.minutes)
                unitText(BigDoseDurationStyle.minuteSuffix, color: unitForeground)
            }
        }
    }

    private func valueText(_ value: Int) -> Text {
        Text("\(value)")
            .font(font)
            .foregroundStyle(valueColor)
    }

    private func unitText(_ unit: String, color: Color) -> Text {
        Text(unit)
            .font(font)
            .foregroundStyle(color)
    }
}
