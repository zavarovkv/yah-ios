import Foundation
import SwiftData

extension AppSchemaV1 {
    @Model
    final class UserProfile {
        static let primaryIdentifier = "primary"

        var identifier: String = AppSchemaV1.UserProfile.primaryIdentifier
        var name: String = ""

        @Attribute(.externalStorage)
        var avatarData: Data?

        var updatedAt: Date = Date.now

        init(
            identifier: String = AppSchemaV1.UserProfile.primaryIdentifier,
            name: String = "",
            avatarData: Data? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.avatarData = avatarData
            updatedAt = .now
        }
    }
}

extension AppSchemaV2 {
    @Model
    final class UserProfile {
        static let primaryIdentifier = "primary"

        var identifier: String = AppSchemaV2.UserProfile.primaryIdentifier
        var name: String = ""

        @Attribute(.externalStorage)
        var avatarData: Data?

        var updatedAt: Date = Date.now

        init(
            identifier: String = AppSchemaV2.UserProfile.primaryIdentifier,
            name: String = "",
            avatarData: Data? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.avatarData = avatarData
            updatedAt = .now
        }
    }
}

typealias UserProfile = AppSchemaV2.UserProfile
