import Foundation
import SwiftData

@Model
final class SkinAssessment {
    #Index<SkinAssessment>([\.createdAt])

    var createdAt: Date = Date.now
    var selectedType: FitzpatrickSkinType = FitzpatrickSkinType.typeII
    var confidence: Double = 1
    var source: String = "manual"

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
