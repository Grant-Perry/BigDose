import SwiftUI
import UIKit

enum InfoBoxMarkdown {
    private static let sectionHeaders: Set<String> = [
        "What it does",
        "What it is",
        "How to use",
        "How BigDose uses it",
        "How we calculate it",
        "What it is not",
        "Tip",
        "Good to know",
        "Watch for"
    ]

    private static let stepLinePrefix = "▸ "

    static func attributedBody(from markdown: String) -> AttributedString {
        var combined = AttributedString()
        let blocks = markdown.components(separatedBy: "\n\n")

        for (index, block) in blocks.enumerated() {
            let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if index > 0, !combined.characters.isEmpty {
                combined.append(AttributedString("\n\n"))
            }

            if trimmed.contains("\n\(stepLinePrefix)") || trimmed.hasPrefix(stepLinePrefix) {
                combined.append(attributedStepBlock(from: trimmed))
            } else {
                combined.append(attributedInlineBlock(from: trimmed))
            }
        }

        return combined
    }

    private static func attributedStepBlock(from block: String) -> AttributedString {
        let lines = block.components(separatedBy: "\n")
        var combined = AttributedString()

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            if index > 0, !combined.characters.isEmpty {
                combined.append(AttributedString("\n"))
            }

            if trimmedLine.hasPrefix(stepLinePrefix) {
                var stepLine = AttributedString(stepLinePrefix)
                stepLine.font = .subheadline.weight(.heavy)
                stepLine.foregroundColor = .solarGold
                stepLine.append(attributedStepLineBody(from: String(trimmedLine.dropFirst(stepLinePrefix.count))))
                applyStepParagraphSpacing(to: &stepLine)
                combined.append(stepLine)
            } else {
                combined.append(attributedInlineBlock(from: trimmedLine))
            }
        }

        return combined
    }

    private static func attributedInlineBlock(from markdown: String) -> AttributedString {
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

    private static func attributedStepLineBody(from markdown: String) -> AttributedString {
        var result = attributedInlineBlock(from: markdown)
        applyStepLabelGold(to: &result)
        return result
    }

    private static func applyStepLabelGold(to attributed: inout AttributedString) {
        for run in attributed.runs {
            guard let intent = attributed[run.range].inlinePresentationIntent,
                  intent.contains(.stronglyEmphasized) else { continue }

            let text = String(attributed[run.range].characters)
            guard !isSectionHeader(text) else { continue }

            attributed[run.range].font = .subheadline.weight(.heavy)
            attributed[run.range].foregroundColor = .solarGold
            break
        }
    }

    private static func applyStepParagraphSpacing(to attributed: inout AttributedString) {
        guard !attributed.characters.isEmpty else { return }

        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 14
        paragraphStyle.paragraphSpacingBefore = 7
        paragraphStyle.lineSpacing = 2

        var container = AttributeContainer()
        container[AttributeScopes.UIKitAttributes.ParagraphStyleAttribute.self] = paragraphStyle
        attributed.mergeAttributes(container)
    }

    private static func isSectionHeader(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix(":") else { return false }
        let label = String(trimmed.dropLast())
        return sectionHeaders.contains(label)
    }
}
