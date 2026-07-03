import SwiftUI

struct SunSessionLiveActivityMetricsColumn: View {
    let attributes: SunSessionActivityAttributes
    let state: SunSessionActivityAttributes.ContentState
    var iuFont: Font = .system(size: 34, weight: .black, design: .rounded)
    var progressWidth: CGFloat = 112

    var body: some View {
        SunSessionLiveUpdatingMetricsView(attributes: attributes, state: state) { estimatedIU, goalProgress in
            SunSessionLiveActivityLiveMetricsColumn(
                attributes: attributes,
                state: state,
                estimatedIU: estimatedIU,
                goalProgress: goalProgress,
                iuFont: iuFont,
                progressWidth: progressWidth
            )
        }
    }
}
