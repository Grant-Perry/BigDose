import SwiftUI

enum InfoBoxMarkdown {
    private static let sectionHeaders: Set<String> = [
        "What it does",
        "What it is",
        "How to use",
        "How BigDose uses it",
        "What it is not",
        "Tip",
        "Good to know",
        "Watch for"
    ]

    static func attributedBody(from markdown: String) -> AttributedString {
        guard var result = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return AttributedString(markdown)
        }

        let baseFont = Font.subheadline.weight(.medium)
        let baseColor = Color.white.opacity(0.78)
        result.font = baseFont
        result.foregroundColor = baseColor

        for run in result.runs {
            let range = run.range

            if let intent = result[range].inlinePresentationIntent {
                if intent.contains(.stronglyEmphasized) {
                    let text = String(result[range].characters)

                    if isSectionHeader(text) {
                        result[range].font = .subheadline.weight(.heavy)
                        result[range].foregroundColor = .solarGold
                    } else {
                        result[range].font = .subheadline.weight(.bold)
                        result[range].foregroundColor = .white.opacity(0.94)
                    }
                    continue
                }

                if intent.contains(.emphasized) {
                    result[range].font = .subheadline.weight(.medium).italic()
                    result[range].foregroundColor = .white.opacity(0.86)
                }
            }
        }

        return result
    }

    private static func isSectionHeader(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix(":") else { return false }
        let label = String(trimmed.dropLast())
        return sectionHeaders.contains(label)
    }
}
