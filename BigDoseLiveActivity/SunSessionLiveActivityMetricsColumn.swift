import SwiftUI

struct SunSessionLiveActivityMetricsColumn: View {
    let attributes: SunSessionActivityAttributes
    let state: SunSessionActivityAttributes.ContentState
    var iuFont: Font = .system(size: 34, weight: .black, design: .rounded)
    var progressWidth: CGFloat = 112

    var body: some View {
        SunSessionLiveActivityLiveMetricsColumn(
            attributes: attributes,
            state: state,
            iuFont: iuFont,
            progressWidth: progressWidth
        )
    }
}
