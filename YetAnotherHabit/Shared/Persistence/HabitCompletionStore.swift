import Foundation
import SwiftData

@MainActor
enum HabitCompletionStore {
    static let maximumDailyCount = Int.max

    static func setCount(
        _ count: Int,
        habit: Habit,
        date: Date,
        calendar: Calendar,
        context: ModelContext
    ) throws {
        let normalizedCount = max(0, count)
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

        if normalizedCount > 0 {
            if storedCompletions.isEmpty {
                context.insert(
                    HabitCompletion(
                        date: normalizedDate,
                        dayKey: dayKey,
                        count: normalizedCount,
                        habit: habit
                    )
                )
            } else {
                // Cloud merges can temporarily produce duplicates. Keep one
                // canonical record and make every write idempotent.
                let canonicalCompletion = storedCompletions[0]
                canonicalCompletion.identifier = identifier
                canonicalCompletion.dayKey = dayKey
                canonicalCompletion.date = normalizedDate
                canonicalCompletion.isCompleted = true
                canonicalCompletion.count = normalizedCount
                canonicalCompletion.habit = habit
                storedCompletions.dropFirst().forEach(context.delete)
            }
        } else {
            storedCompletions.forEach(context.delete)
        }

        try context.save()
    }
}
