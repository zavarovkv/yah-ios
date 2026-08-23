import Foundation

enum HabitDayPolicy {
    static func canChangeStatus(
        on date: Date,
        today: Date = .now,
        calendar: Calendar
    ) -> Bool {
        guard let distance = dayDistance(from: date, to: today, calendar: calendar) else {
            return false
        }
        return (0...1).contains(distance)
    }

    static func isHistorical(
        _ date: Date,
        today: Date = .now,
        calendar: Calendar
    ) -> Bool {
        guard let distance = dayDistance(from: date, to: today, calendar: calendar) else {
            return false
        }
        return distance >= 2
    }

    private static func dayDistance(
        from date: Date,
        to today: Date,
        calendar: Calendar
    ) -> Int? {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: today)
        return calendar.dateComponents([.day], from: day, to: today).day
    }
}
