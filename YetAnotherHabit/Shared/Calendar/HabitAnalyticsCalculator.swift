import Foundation

enum HabitAnalyticsCalculator {
    struct Snapshot: Equatable {
        let currentStreak: Int
        let bestStreak: Int
        let completedCount: Int
        let recentCompletedCount: Int
        let recentScheduledCount: Int

        var recentProgress: Double? {
            guard recentScheduledCount > 0 else { return nil }
            return Double(recentCompletedCount) / Double(recentScheduledCount)
        }
    }

    enum DayStatus: Equatable {
        case unavailable
        case unscheduled
        case upcoming
        case pending
        case missed
        case completed
    }

    static func snapshot(
        for habit: Habit,
        completedIdentifiers: Set<String>,
        through endDate: Date,
        recentDayCount: Int = 30,
        calendar: Calendar
    ) -> Snapshot {
        let startDate = calendar.startOfDay(for: habit.createdAt)
        let endDate = calendar.startOfDay(for: endDate)
        guard startDate <= endDate else {
            return Snapshot(
                currentStreak: 0,
                bestStreak: 0,
                completedCount: 0,
                recentCompletedCount: 0,
                recentScheduledCount: 0
            )
        }

        if habit.kind == .counter, habit.effectiveCounterInterval != .daily {
            return intervalSnapshot(
                for: habit,
                completedIdentifiers: completedIdentifiers,
                through: endDate,
                recentDayCount: recentDayCount,
                calendar: calendar
            )
        }

        let recentStart = calendar.date(
            byAdding: .day,
            value: -(max(recentDayCount, 1) - 1),
            to: endDate
        ) ?? endDate

        var bestStreak = 0
        var runningStreak = 0
        var completedCount = 0
        var recentCompletedCount = 0
        var recentScheduledCount = 0
        var date = startDate

        while date <= endDate {
            if habit.isScheduled(on: date, calendar: calendar) {
                let isCompleted = completedIdentifiers.contains(
                    HabitCompletionPeriod.identifier(
                        for: habit,
                        containing: date,
                        calendar: calendar
                    )
                )

                if isCompleted {
                    completedCount += 1
                    runningStreak += 1
                    bestStreak = max(bestStreak, runningStreak)
                } else {
                    runningStreak = 0
                }

                if date >= recentStart {
                    recentScheduledCount += 1
                    if isCompleted {
                        recentCompletedCount += 1
                    }
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                break
            }
            date = nextDate
        }

        return Snapshot(
            currentStreak: HabitStreakCalculator.streak(
                for: habit,
                through: endDate,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            ),
            bestStreak: bestStreak,
            completedCount: completedCount,
            recentCompletedCount: recentCompletedCount,
            recentScheduledCount: recentScheduledCount
        )
    }

    private static func intervalSnapshot(
        for habit: Habit,
        completedIdentifiers: Set<String>,
        through endDate: Date,
        recentDayCount: Int,
        calendar: Calendar
    ) -> Snapshot {
        let recentStart = calendar.date(
            byAdding: .day,
            value: -(max(recentDayCount, 1) - 1),
            to: endDate
        ) ?? endDate
        let lastPeriodStart = HabitCompletionPeriod.start(
            for: habit,
            containing: endDate,
            calendar: calendar
        )
        var periodStart = HabitCompletionPeriod.start(
            for: habit,
            containing: habit.createdAt,
            calendar: calendar
        )
        var bestStreak = 0
        var runningStreak = 0
        var completedCount = 0
        var recentCompletedCount = 0
        var recentScheduledCount = 0

        while periodStart <= lastPeriodStart {
            let hasScheduledOccurrence = HabitCompletionPeriod.hasScheduledOccurrence(
                for: habit,
                periodStartingAt: periodStart,
                through: endDate,
                calendar: calendar
            )

            if hasScheduledOccurrence {
                let identifier = HabitCompletionPeriod.identifier(
                    for: habit,
                    containing: periodStart,
                    calendar: calendar
                )
                let isCompleted = completedIdentifiers.contains(identifier)

                if isCompleted {
                    completedCount += 1
                    runningStreak += 1
                    bestStreak = max(bestStreak, runningStreak)
                } else {
                    runningStreak = 0
                }

                if HabitCompletionPeriod.hasScheduledOccurrence(
                    for: habit,
                    periodStartingAt: periodStart,
                    notBefore: recentStart,
                    through: endDate,
                    calendar: calendar
                ) {
                    recentScheduledCount += 1
                    if isCompleted {
                        recentCompletedCount += 1
                    }
                }
            }

            guard let nextStart = HabitCompletionPeriod.nextStart(
                after: periodStart,
                for: habit,
                calendar: calendar
            ) else {
                break
            }
            periodStart = nextStart
        }

        return Snapshot(
            currentStreak: HabitStreakCalculator.streak(
                for: habit,
                through: endDate,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            ),
            bestStreak: bestStreak,
            completedCount: completedCount,
            recentCompletedCount: recentCompletedCount,
            recentScheduledCount: recentScheduledCount
        )
    }

    static func status(
        for date: Date,
        habit: Habit,
        completedIdentifiers: Set<String>,
        today: Date = .now,
        calendar: Calendar
    ) -> DayStatus {
        let date = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: today)
        guard date >= calendar.startOfDay(for: habit.createdAt) else {
            return .unavailable
        }
        guard habit.isScheduled(on: date, calendar: calendar) else {
            return .unscheduled
        }
        guard date <= today else {
            return .upcoming
        }

        let identifier = HabitCompletionPeriod.identifier(
            for: habit,
            containing: date,
            calendar: calendar
        )
        if completedIdentifiers.contains(identifier) {
            return .completed
        }

        let isCurrentPeriod = HabitCompletionPeriod.start(
            for: habit,
            containing: date,
            calendar: calendar
        ) == HabitCompletionPeriod.start(
            for: habit,
            containing: today,
            calendar: calendar
        )
        return date == today || isCurrentPeriod ? .pending : .missed
    }
}
