import Foundation
import SwiftData

@Model
final class BadgeAward {
    #Index<BadgeAward>([\.awardedAt])

    var awardedAt: Date
    var badgeID: String
    var title: String
    var detail: String

    init(awardedAt: Date = .now, badgeID: String, title: String, detail: String = "") {
        self.awardedAt = awardedAt
        self.badgeID = badgeID
        self.title = title
        self.detail = detail
    }
}
