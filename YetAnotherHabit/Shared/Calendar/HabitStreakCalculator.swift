import Foundation

enum HabitStreakCalculator {
    static func streakBefore(
        _ date: Date,
        for habit: Habit,
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Int {
        guard let previousDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: calendar.startOfDay(for: date)
        ) else {
            return 0
        }

        return streak(
            for: habit,
            through: previousDate,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    static func streak(
        for habit: Habit,
        through date: Date,
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Int {
        if habit.kind == .counter, habit.effectiveCounterInterval != .daily {
            return intervalStreak(
                for: habit,
                through: date,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            )
        }

        let startDate = calendar.startOfDay(for: habit.createdAt)
        var date = calendar.startOfDay(for: date)
        var streak = 0

        while date >= startDate {
            guard habit.isScheduled(on: date, calendar: calendar) else {
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else {
                    break
                }
                date = previousDate
                continue
            }

            let identifier = HabitCompletionPeriod.identifier(
                for: habit,
                containing: date,
                calendar: calendar
            )
            guard completedIdentifiers.contains(identifier) else { break }

            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: date) else {
                break
            }
            date = previousDate
        }

        return streak
    }

    private static func intervalStreak(
        for habit: Habit,
        through date: Date,
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Int {
        let endDate = calendar.startOfDay(for: date)
        let firstPeriodStart = HabitCompletionPeriod.start(
            for: habit,
            containing: habit.createdAt,
            calendar: calendar
        )
        var periodStart = HabitCompletionPeriod.start(
            for: habit,
            containing: endDate,
            calendar: calendar
        )
        var streak = 0

        while periodStart >= firstPeriodStart {
            if HabitCompletionPeriod.hasScheduledOccurrence(
                for: habit,
                periodStartingAt: periodStart,
                through: endDate,
                calendar: calendar
            ) {
                let identifier = HabitCompletionPeriod.identifier(
                    for: habit,
                    containing: periodStart,
                    calendar: calendar
                )
                guard completedIdentifiers.contains(identifier) else { break }
                streak += 1
            }

            guard let previousStart = HabitCompletionPeriod.previousStart(
                before: periodStart,
                for: habit,
                calendar: calendar
            ) else {
                break
            }
            periodStart = previousStart
        }

        return streak
    }
}
