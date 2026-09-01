import Foundation
import SwiftData

@MainActor
enum DataMaintenance {
    static let currentVersion = 1

    static func reconcile(
        context: ModelContext,
        calendar: Calendar,
        locale: Locale,
        repairCompletions: Bool = true
    ) throws {
        if repairCompletions {
            try reconcileCompletions(context: context, calendar: calendar)
        }
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        _ = UserProfileReconciler.reconcile(profiles, in: context, locale: locale)
        if context.hasChanges {
            try context.save()
        }
    }

    private static func reconcileCompletions(
        context: ModelContext,
        calendar: Calendar
    ) throws {
        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        HabitCompletionStore.reconcileBuckets(
            completions,
            calendar: calendar,
            context: context
        )
    }
}
