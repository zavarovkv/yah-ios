import Foundation
import SwiftData

@Model
final class UserProfile {
    static let primaryIdentifier = "primary"

    var identifier: String = UserProfile.primaryIdentifier
    var name: String = ""

    @Attribute(.externalStorage)
    var avatarData: Data?

    var updatedAt: Date = Date.now

    init(
        identifier: String = UserProfile.primaryIdentifier,
        name: String = "",
        avatarData: Data? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.avatarData = avatarData
        self.updatedAt = .now
    }
}
