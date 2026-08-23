import Foundation

enum MonthGrid {
    struct Cell: Identifiable, Equatable {
        let id: Int
        let date: Date?
    }

    static func start(of date: Date, calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? date
    }

    static func addingMonths(
        _ value: Int,
        to month: Date,
        calendar: Calendar
    ) -> Date {
        guard let date = calendar.date(byAdding: .month, value: value, to: month) else {
            return month
        }
        return start(of: date, calendar: calendar)
    }

    static func cells(for month: Date, calendar: Calendar) -> [Cell] {
        guard
            let dayRange = calendar.range(of: .day, in: .month, for: month),
            let firstDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month)
            )
        else {
            return []
        }

        let leadingEmptyDays = WeekCalendar.mondayBasedWeekday(
            for: firstDate,
            calendar: calendar
        )
        let emptyCells = (0..<leadingEmptyDays).map {
            Cell(id: $0, date: nil)
        }
        let dateCells = dayRange.compactMap { day -> Cell? in
            guard let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDate
            ) else {
                return nil
            }
            return Cell(id: leadingEmptyDays + day - 1, date: date)
        }
        return emptyCells + dateCells
    }
}
