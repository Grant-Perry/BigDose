import Foundation
import WidgetKit

enum BigDoseWidgetReloader {
    static func reloadHomeWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: BigDoseWidgetKind.home)
    }
}
