import Foundation

enum HabitDaySorter {
    static func belongsToCompletedSection(_ habit: Habit, count: Int) -> Bool {
        switch habit.kind {
        case .habit:
            return count > 0
        case .counter:
            guard habit.effectiveTargetCount != nil else { return false }
            return habit.isGoalMet(by: count)
        }
    }

    static func incompleteCount(
        in habits: [Habit],
        for date: Date,
        completionCounts: [String: Int],
        calendar: Calendar
    ) -> Int {
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        return habits.lazy.filter { habit in
            guard
                habit.contributesToDailyGoal,
                habit.isScheduled(on: date, calendar: calendar)
            else {
                return false
            }
            let identifier = HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: dayKey
            )
            return !habit.isGoalMet(by: completionCounts[identifier, default: 0])
        }.count
    }

    static func sorted(
        _ habits: [Habit],
        for date: Date,
        completionCounts: [String: Int],
        calendar: Calendar
    ) -> [Habit] {
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)

        return habits.sorted { lhs, rhs in
            let lhsRank = rank(
                for: lhs,
                dayKey: dayKey,
                completionCounts: completionCounts
            )
            let rhsRank = rank(
                for: rhs,
                dayKey: dayKey,
                completionCounts: completionCounts
            )

            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.identifier.uuidString < rhs.identifier.uuidString
        }
    }

    private static func rank(
        for habit: Habit,
        dayKey: String,
        completionCounts: [String: Int]
    ) -> Int {
        if habit.kind == .counter, habit.effectiveTargetCount == nil {
            return 2
        }

        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: dayKey
        )
        return habit.isGoalMet(by: completionCounts[identifier, default: 0]) ? 1 : 0
    }
}
