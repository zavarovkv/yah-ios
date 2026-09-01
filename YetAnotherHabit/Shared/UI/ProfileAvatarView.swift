import SwiftUI
import UIKit

private enum ProfileAvatarImageCache {
    static let cache: NSCache<NSData, UIImage> = {
        let cache = NSCache<NSData, UIImage>()
        cache.totalCostLimit = 8 * 1_024 * 1_024
        return cache
    }()

    static func image(for data: Data) -> UIImage? {
        let key = data as NSData
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        guard let image = UIImage(data: data) else { return nil }
        let pixelWidth = image.cgImage?.width ?? 0
        let pixelHeight = image.cgImage?.height ?? 0
        cache.setObject(image, forKey: key, cost: pixelWidth * pixelHeight * 4)
        return image
    }
}

struct ProfileAvatarView: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if
                let data,
                let image = ProfileAvatarImageCache.image(for: data)
            {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }
}
