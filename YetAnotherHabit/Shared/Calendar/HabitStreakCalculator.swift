import Foundation

enum HabitStreakCalculator {
    static func streak(
        for habit: Habit,
        through date: Date,
        completedIdentifiers: Set<String>,
        calendar: Calendar
    ) -> Int {
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

            let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
            let identifier = HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: dayKey
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
}
