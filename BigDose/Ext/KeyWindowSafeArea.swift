import UIKit

enum KeyWindowSafeArea {
    /// Status-bar clearance for full-screen covers that report zero SwiftUI safe area.
    @MainActor
    static var top: CGFloat {
        let measured = keyWindow?.safeAreaInsets.top ?? 0
        if measured > 20 {
            return measured
        }

        // fullScreenCover windows often report 0 — use a notch-safe default.
        return 59
    }

    @MainActor
    private static var keyWindow: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if let key = windowScene.windows.first(where: \.isKeyWindow) {
                return key
            }
            if let first = windowScene.windows.first {
                return first
            }
        }

        return nil
    }
}
