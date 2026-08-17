import Foundation

enum HabitProgressCalculator {
    struct Snapshot: Equatable {
        let completedCount: Int
        let scheduledCount: Int

        var progress: Double {
            guard scheduledCount > 0 else { return 0 }
            return Double(completedCount) / Double(scheduledCount)
        }
    }

    static func snapshot(
        for dates: [Date],
        habits: [Habit],
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Snapshot {
        var scheduledCount = 0
        var completedCount = 0

        for date in dates {
            let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
            for habit in habits where habit.isScheduled(on: date, calendar: calendar) {
                scheduledCount += 1
                let identifier = HabitCompletion.identifier(
                    habitID: habit.identifier,
                    dayKey: dayKey
                )
                if completedIdentifiers.contains(identifier) {
                    completedCount += 1
                }
            }
        }

        return Snapshot(
            completedCount: completedCount,
            scheduledCount: scheduledCount
        )
    }

    static func progress(
        for date: Date,
        habits: [Habit],
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Double? {
        let snapshot = snapshot(
            for: [date],
            habits: habits,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
        guard snapshot.scheduledCount > 0 else { return nil }
        return snapshot.progress
    }
}
