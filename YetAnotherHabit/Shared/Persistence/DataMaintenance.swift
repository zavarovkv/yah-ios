import Foundation
import SwiftData

@MainActor
enum DataMaintenance {
    static func reconcile(
        context: ModelContext,
        calendar: Calendar,
        locale: Locale
    ) throws {
        try reconcileCompletions(context: context, calendar: calendar)
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        _ = UserProfileReconciler.reconcile(profiles, in: context, locale: locale)
        try context.save()
    }

    private static func reconcileCompletions(
        context: ModelContext,
        calendar: Calendar
    ) throws {
        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        var canonicalCompletions: [String: HabitCompletion] = [:]

        for completion in completions {
            guard completion.isCompleted, completion.count > 0 else {
                context.delete(completion)
                continue
            }

            guard let habit = completion.habit else {
                context.delete(completion)
                continue
            }

            let dayKey = WeekCalendar.dayKey(for: completion.date, calendar: calendar)
            let identifier = HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: dayKey
            )
            completion.dayKey = dayKey
            completion.identifier = identifier
            completion.date = calendar.startOfDay(for: completion.date)

            if let canonical = canonicalCompletions[identifier] {
                canonical.count = max(canonical.count, completion.count)
                context.delete(completion)
            } else {
                canonicalCompletions[identifier] = completion
            }
        }
    }
}
