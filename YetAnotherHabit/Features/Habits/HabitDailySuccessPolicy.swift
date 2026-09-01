import Foundation

enum HabitDailySuccessPolicy {
    struct Snapshot: Equatable {
        let completedCount: Int
        let goalCount: Int

        var isComplete: Bool {
            goalCount > 0 && completedCount == goalCount
        }
    }

    static func snapshot(
        for date: Date,
        habits: [Habit],
        completionCounts: [String: Int],
        today: Date = .now,
        calendar: Calendar
    ) -> Snapshot {
        guard HabitDayPolicy.canChangeStatus(
            on: date,
            today: today,
            calendar: calendar
        ) else {
            return Snapshot(completedCount: 0, goalCount: 0)
        }

        let goalHabits = habits.filter { habit in
            HabitCompletionPeriod.isGoalDue(
                for: habit,
                on: date,
                calendar: calendar
            )
        }
        let completedCount = goalHabits.reduce(into: 0) { result, habit in
            let identifier = HabitCompletionPeriod.identifier(
                for: habit,
                containing: date,
                calendar: calendar
            )
            if habit.isGoalMet(by: completionCounts[identifier, default: 0]) {
                result += 1
            }
        }

        return Snapshot(
            completedCount: completedCount,
            goalCount: goalHabits.count
        )
    }

    static func shouldShowBanner(
        for date: Date,
        habits: [Habit],
        completionCounts: [String: Int],
        today: Date = .now,
        calendar: Calendar
    ) -> Bool {
        snapshot(
            for: date,
            habits: habits,
            completionCounts: completionCounts,
            today: today,
            calendar: calendar
        ).isComplete
    }
}
