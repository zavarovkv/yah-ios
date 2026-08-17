import SwiftData

@MainActor
enum UserProfileReconciler {
    static func reconcile(
        _ profiles: [UserProfile],
        in context: ModelContext
    ) -> UserProfile? {
        let sortedProfiles = profiles.sorted { $0.updatedAt > $1.updatedAt }
        guard let primary = sortedProfiles.first else { return nil }

        for duplicate in sortedProfiles.dropFirst() {
            if primary.name.isEmpty, !duplicate.name.isEmpty {
                primary.name = duplicate.name
            }
            if primary.avatarData == nil, duplicate.avatarData != nil {
                primary.avatarData = duplicate.avatarData
            }
            context.delete(duplicate)
        }

        primary.identifier = UserProfile.primaryIdentifier
        return primary
    }
}
