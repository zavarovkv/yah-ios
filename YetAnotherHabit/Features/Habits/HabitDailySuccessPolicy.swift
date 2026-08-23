import Foundation

enum HabitDailySuccessPolicy {
    static func shouldShowBanner(
        for date: Date,
        habits: [Habit],
        completionCounts: [String: Int],
        today: Date = .now,
        calendar: Calendar
    ) -> Bool {
        guard HabitDayPolicy.canChangeStatus(
            on: date,
            today: today,
            calendar: calendar
        ) else {
            return false
        }

        let goalHabits = habits.filter { habit in
            habit.isScheduled(on: date, calendar: calendar)
                && habit.contributesToDailyGoal
        }
        guard !goalHabits.isEmpty else { return false }

        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        return goalHabits.allSatisfy { habit in
            let identifier = HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: dayKey
            )
            return habit.isGoalMet(by: completionCounts[identifier, default: 0])
        }
    }
}
