import Foundation

enum WeekCalendar {
    static func startOfWeek(
        containing date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        mondayBased(calendar)
            .dateInterval(of: .weekOfYear, for: date)?
            .start ?? date
    }

    static func endOfWeek(starting weekStart: Date, calendar: Calendar) -> Date {
        mondayBased(calendar)
            .date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    static func addWeeks(_ value: Int, to weekStart: Date, calendar: Calendar) -> Date? {
        mondayBased(calendar)
            .date(byAdding: .weekOfYear, value: value, to: weekStart)
    }

    static func dates(starting weekStart: Date, calendar: Calendar) -> [Date] {
        let calendar = mondayBased(calendar)
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    static func containsToday(_ weekStart: Date, calendar: Calendar) -> Bool {
        dates(starting: weekStart, calendar: calendar)
            .contains { calendar.isDateInToday($0) }
    }

    static func isWeekend(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = mondayBased(calendar).component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    static func weekdayTitle(
        for date: Date,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let weekday = mondayBased(calendar).component(.weekday, from: date)
        return weekdayTitle(forMondayBasedIndex: (weekday + 5) % 7, locale: locale)
    }

    static func weekdayTitle(
        forMondayBasedIndex index: Int,
        locale: Locale
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let normalizedIndex = ((index % 7) + 7) % 7
        let sundayBasedIndex = (normalizedIndex + 1) % 7
        let symbol = calendar.shortStandaloneWeekdaySymbols[sundayBasedIndex]
        return symbol.prefix(1).uppercased(with: locale) + symbol.dropFirst()
    }

    static func mondayBasedWeekday(for date: Date, calendar: Calendar) -> Int {
        let weekday = mondayBased(calendar).component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func selectedDate(
        whenMovingTo weekStart: Date,
        direction: Int,
        calendar: Calendar,
        now: Date = .now
    ) -> Date {
        if dates(starting: weekStart, calendar: calendar)
            .contains(where: { calendar.isDate($0, inSameDayAs: now) })
        {
            return now
        }

        return direction > 0
            ? weekStart
            : endOfWeek(starting: weekStart, calendar: calendar)
    }

    private static func mondayBased(_ calendar: Calendar) -> Calendar {
        var calendar = calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }
}
