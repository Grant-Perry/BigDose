import SwiftUI
import UIKit

enum BigDoseNavigationAppearance {
    static func configure() {
        guard let titleFont = UIFont(name: BigDoseFontFamily.bebasNeue, size: 22),
              let largeTitleFont = UIFont(name: BigDoseFontFamily.bebasNeue, size: 34)
        else {
            return
        }

        let standard = UINavigationBarAppearance()
        standard.configureWithTransparentBackground()
        standard.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        standard.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .foregroundColor: UIColor.white
        ]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = standard
        navBar.compactAppearance = standard
        navBar.scrollEdgeAppearance = standard
    }
}
