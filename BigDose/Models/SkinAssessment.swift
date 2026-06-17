import Foundation
import SwiftData

@Model
final class SkinAssessment {
    #Index<SkinAssessment>([\.createdAt])

    var createdAt: Date
    var selectedType: FitzpatrickSkinType
    var confidence: Double
    var source: String

    init(
        createdAt: Date = .now,
        selectedType: FitzpatrickSkinType = .typeII,
        confidence: Double = 1,
        source: String = "manual"
    ) {
        self.createdAt = createdAt
        self.selectedType = selectedType
        self.confidence = confidence
        self.source = source
    }
}
