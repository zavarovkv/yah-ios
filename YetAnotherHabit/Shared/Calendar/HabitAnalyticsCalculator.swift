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
                    HabitCompletion.identifier(
                        habitID: habit.identifier,
                        dayKey: WeekCalendar.dayKey(for: date, calendar: calendar)
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

        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: date, calendar: calendar)
        )
        if completedIdentifiers.contains(identifier) {
            return .completed
        }
        return date == today ? .pending : .missed
    }
}
