import Foundation
import SwiftData

@MainActor
enum DataMaintenance {
    static func reconcile(context: ModelContext, calendar: Calendar) throws {
        try reconcileCompletions(context: context, calendar: calendar)
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        _ = UserProfileReconciler.reconcile(profiles, in: context)
        try context.save()
    }

    private static func reconcileCompletions(
        context: ModelContext,
        calendar: Calendar
    ) throws {
        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        var identifiers = Set<String>()

        for completion in completions {
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

            if !identifiers.insert(identifier).inserted {
                context.delete(completion)
            }
        }
    }
}
