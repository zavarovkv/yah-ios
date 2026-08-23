import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if
                let data,
                let image = UIImage(data: data)
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
