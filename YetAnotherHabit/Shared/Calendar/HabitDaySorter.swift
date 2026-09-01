import Foundation

enum HabitDaySorter {
    struct Sections {
        let pending: [Habit]
        let openCounters: [Habit]
        let completed: [Habit]
    }

    static func belongsToCompletedSection(_ habit: Habit, count: Int) -> Bool {
        switch habit.kind {
        case .habit:
            return count > 0
        case .counter:
            guard habit.effectiveTargetCount != nil else { return false }
            return habit.isGoalMet(by: count)
        }
    }

    static func movesToCompletedSection(
        _ habit: Habit,
        from previousCount: Int,
        to newCount: Int
    ) -> Bool {
        !belongsToCompletedSection(habit, count: previousCount)
            && belongsToCompletedSection(habit, count: newCount)
    }

    static func belongsToCountersSection(
        _ habit: Habit,
        count: Int,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        guard
            habit.kind == .counter,
            !belongsToCompletedSection(habit, count: count)
        else {
            return false
        }

        return habit.effectiveTargetCount == nil
            || !HabitCompletionPeriod.isGoalDue(for: habit, on: date, calendar: calendar)
    }

    static func incompleteCount(
        in habits: [Habit],
        for date: Date,
        completionCounts: [String: Int],
        calendar: Calendar
    ) -> Int {
        return habits.lazy.filter { habit in
            guard HabitCompletionPeriod.isGoalDue(
                for: habit,
                on: date,
                calendar: calendar
            ) else {
                return false
            }
            let identifier = HabitCompletionPeriod.identifier(
                for: habit,
                containing: date,
                calendar: calendar
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
        return habits.sorted { lhs, rhs in
            let lhsRank = rank(
                for: lhs,
                date: date,
                completionCounts: completionCounts,
                calendar: calendar
            )
            let rhsRank = rank(
                for: rhs,
                date: date,
                completionCounts: completionCounts,
                calendar: calendar
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

    static func sections(
        in habits: [Habit],
        for date: Date,
        calendar: Calendar,
        countFor: (Habit) -> Int
    ) -> Sections {
        var pending: [Habit] = []
        var openCounters: [Habit] = []
        var completed: [Habit] = []

        for habit in habits {
            let count = countFor(habit)

            if belongsToCompletedSection(habit, count: count) {
                completed.append(habit)
            } else if belongsToCountersSection(
                habit,
                count: count,
                on: date,
                calendar: calendar
            ) {
                openCounters.append(habit)
            } else if habit.contributesToDailyGoal {
                pending.append(habit)
            }
        }

        return Sections(
            pending: pending,
            openCounters: openCounters,
            completed: completed
        )
    }

    private static func rank(
        for habit: Habit,
        date: Date,
        completionCounts: [String: Int],
        calendar: Calendar
    ) -> Int {
        let identifier = HabitCompletionPeriod.identifier(
            for: habit,
            containing: date,
            calendar: calendar
        )
        let count = completionCounts[identifier, default: 0]
        if belongsToCompletedSection(habit, count: count) {
            return 1
        }
        if belongsToCountersSection(
            habit,
            count: count,
            on: date,
            calendar: calendar
        ) {
            return 2
        }
        return 0
    }
}
