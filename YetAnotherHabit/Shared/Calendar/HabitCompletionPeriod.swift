import Foundation

enum HabitCompletionPeriod {
    static func start(
        for habit: Habit,
        containing date: Date,
        calendar: Calendar
    ) -> Date {
        let date = calendar.startOfDay(for: date)

        switch habit.effectiveCounterInterval {
        case .daily:
            return date
        case .weekly:
            return WeekCalendar.startOfWeek(containing: date, calendar: calendar)
        case .biweekly:
            let anchor = WeekCalendar.startOfWeek(
                containing: habit.createdAt,
                calendar: calendar
            )
            let elapsedDays = calendar.dateComponents([.day], from: anchor, to: date).day ?? 0
            return calendar.date(
                byAdding: .day,
                value: (elapsedDays / 14) * 14,
                to: anchor
            ).map(calendar.startOfDay(for:)) ?? anchor
        case .monthly:
            let components = calendar.dateComponents([.era, .year, .month], from: date)
            return calendar.date(from: components).map(calendar.startOfDay(for:)) ?? date
        case .yearly:
            let components = calendar.dateComponents([.era, .year], from: date)
            return calendar.date(from: components).map(calendar.startOfDay(for:)) ?? date
        }
    }

    static func key(
        for habit: Habit,
        containing date: Date,
        calendar: Calendar
    ) -> String {
        WeekCalendar.dayKey(
            for: start(for: habit, containing: date, calendar: calendar),
            calendar: calendar
        )
    }

    static func identifier(
        for habit: Habit,
        containing date: Date,
        calendar: Calendar
    ) -> String {
        HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: key(for: habit, containing: date, calendar: calendar)
        )
    }

    static func nextStart(
        after periodStart: Date,
        for habit: Habit,
        calendar: Calendar
    ) -> Date? {
        calendar.date(
            byAdding: component(for: habit),
            value: step(for: habit),
            to: periodStart
        ).map(calendar.startOfDay(for:))
    }

    static func previousStart(
        before periodStart: Date,
        for habit: Habit,
        calendar: Calendar
    ) -> Date? {
        calendar.date(
            byAdding: component(for: habit),
            value: -step(for: habit),
            to: periodStart
        ).map {
            start(for: habit, containing: $0, calendar: calendar)
        }
    }

    static func hasScheduledOccurrence(
        for habit: Habit,
        periodStartingAt periodStart: Date,
        notBefore lowerBound: Date? = nil,
        through upperBound: Date,
        calendar: Calendar
    ) -> Bool {
        guard let nextPeriodStart = nextStart(
            after: periodStart,
            for: habit,
            calendar: calendar
        ), let periodEnd = calendar.date(byAdding: .day, value: -1, to: nextPeriodStart)
        else {
            return false
        }

        var date = max(
            max(periodStart, calendar.startOfDay(for: habit.createdAt)),
            lowerBound.map(calendar.startOfDay(for:)) ?? periodStart
        )
        let lastDate = min(calendar.startOfDay(for: upperBound), periodEnd)

        while date <= lastDate {
            if habit.isScheduled(on: date, calendar: calendar) {
                return true
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                return false
            }
            date = nextDate
        }

        return false
    }

    static func isGoalDue(
        for habit: Habit,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        guard
            habit.contributesToDailyGoal,
            habit.isScheduled(on: date, calendar: calendar)
        else {
            return false
        }

        guard habit.kind == .counter, habit.effectiveCounterInterval != .daily else {
            return true
        }

        return isLastScheduledOccurrence(for: habit, on: date, calendar: calendar)
    }

    static func isLastScheduledOccurrence(
        for habit: Habit,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        let date = calendar.startOfDay(for: date)
        guard habit.isScheduled(on: date, calendar: calendar) else { return false }

        let periodStart = start(for: habit, containing: date, calendar: calendar)
        guard let nextPeriodStart = nextStart(
            after: periodStart,
            for: habit,
            calendar: calendar
        ) else {
            return false
        }

        guard var candidate = calendar.date(byAdding: .day, value: 1, to: date) else {
            return true
        }
        while candidate < nextPeriodStart {
            if habit.isScheduled(on: candidate, calendar: calendar) {
                return false
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: candidate) else {
                break
            }
            candidate = nextDate
        }

        return true
    }

    private static func component(for habit: Habit) -> Calendar.Component {
        switch habit.effectiveCounterInterval {
        case .daily:
            .day
        case .weekly:
            .weekOfYear
        case .biweekly:
            .weekOfYear
        case .monthly:
            .month
        case .yearly:
            .year
        }
    }

    private static func step(for habit: Habit) -> Int {
        habit.effectiveCounterInterval == .biweekly ? 2 : 1
    }
}
