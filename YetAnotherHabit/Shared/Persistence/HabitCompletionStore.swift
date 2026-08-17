import Foundation
import SwiftData

@MainActor
enum HabitCompletionStore {
    static func setCompleted(
        _ isCompleted: Bool,
        habit: Habit,
        date: Date,
        calendar: Calendar,
        context: ModelContext
    ) throws {
        let normalizedDate = calendar.startOfDay(for: date)
        let dayKey = WeekCalendar.dayKey(for: normalizedDate, calendar: calendar)
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: dayKey
        )
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        let storedCompletions = try context.fetch(descriptor)

        if isCompleted {
            if storedCompletions.isEmpty {
                context.insert(
                    HabitCompletion(
                        date: normalizedDate,
                        dayKey: dayKey,
                        habit: habit
                    )
                )
            } else {
                // Cloud merges can temporarily produce duplicates. Keep one
                // canonical record and make every write idempotent.
                storedCompletions.dropFirst().forEach(context.delete)
            }
        } else {
            storedCompletions.forEach(context.delete)
        }

        try context.save()
    }
}
