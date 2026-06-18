import SwiftUI
import UIKit

enum ProfileAvatarProcessor {
    static let exportPixelSize: CGFloat = 512
    static let jpegCompressionQuality: CGFloat = 0.82

    @MainActor
    static func jpegData(from image: UIImage, scale: CGFloat, offset: CGSize, cropDiameter: CGFloat) -> Data? {
        guard let cropped = croppedImage(from: image, scale: scale, offset: offset, cropDiameter: cropDiameter) else {
            return nil
        }

        return cropped.jpegData(compressionQuality: jpegCompressionQuality)
    }

    @MainActor
    static func croppedImage(from image: UIImage, scale: CGFloat, offset: CGSize, cropDiameter: CGFloat) -> UIImage? {
        let normalized = image.normalizedOrientation()
        let exportSize = exportPixelSize
        let scaleRatio = exportSize / cropDiameter

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: exportSize, height: exportSize))
        return renderer.image { context in
            let bounds = CGRect(origin: .zero, size: CGSize(width: exportSize, height: exportSize))
            context.cgContext.addEllipse(in: bounds)
            context.cgContext.clip()

            let imageSize = normalized.size
            let fillScale = max(cropDiameter / imageSize.width, cropDiameter / imageSize.height)
            let drawWidth = imageSize.width * fillScale * scale * scaleRatio
            let drawHeight = imageSize.height * fillScale * scale * scaleRatio
            let originX = (exportSize - drawWidth) / 2 + (offset.width * scaleRatio)
            let originY = (exportSize - drawHeight) / 2 + (offset.height * scaleRatio)

            normalized.draw(in: CGRect(x: originX, y: originY, width: drawWidth, height: drawHeight))
        }
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
