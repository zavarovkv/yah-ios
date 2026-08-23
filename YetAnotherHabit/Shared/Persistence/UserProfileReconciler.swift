import Foundation
import SwiftData

@MainActor
enum UserProfileReconciler {
    static func generatedName(locale: Locale) -> String {
        let names = [
            AppLocalization.string("Весёлый Барсук", locale: locale),
            AppLocalization.string("Добрая Лама", locale: locale),
            AppLocalization.string("Ловкий Лис", locale: locale),
            AppLocalization.string("Любопытная Панда", locale: locale),
            AppLocalization.string("Смелая Выдра", locale: locale),
            AppLocalization.string("Тихий Енот", locale: locale)
        ]

        return names.randomElement()
            ?? AppLocalization.string("Весёлый Барсук", locale: locale)
    }

    static func reconcile(
        _ profiles: [UserProfile],
        in context: ModelContext,
        locale: Locale
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
        if primary.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            primary.name = generatedName(locale: locale)
        }
        return primary
    }
}
