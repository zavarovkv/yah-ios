import Foundation
import Testing
@testable import YetAnotherHabit

struct WeekCalendarTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func weekStartsOnMonday() throws {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 19)))
        let start = WeekCalendar.startOfWeek(containing: date, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: start)

        #expect(components == DateComponents(year: 2026, month: 8, day: 17))
    }

    @Test func weekContainsSevenConsecutiveDates() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))
        let dates = WeekCalendar.dates(starting: start, calendar: calendar)

        #expect(dates.count == 7)
        #expect(calendar.component(.day, from: dates[0]) == 17)
        #expect(calendar.component(.day, from: dates[6]) == 23)
    }

    @Test func movingAcrossYearBoundaryKeepsMonday() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 28)))
        let nextWeek = try #require(WeekCalendar.addWeeks(1, to: start, calendar: calendar))
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: nextWeek)

        #expect(components.year == 2027)
        #expect(components.month == 1)
        #expect(components.day == 4)
        #expect(components.weekday == 2)
    }

    @Test func mondayBasedWeekdayUsesZeroThroughSix() throws {
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 23)))

        #expect(WeekCalendar.mondayBasedWeekday(for: monday, calendar: calendar) == 0)
        #expect(WeekCalendar.mondayBasedWeekday(for: sunday, calendar: calendar) == 6)
    }

    @Test func movingToFutureWeekSelectsMonday() throws {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))
        let futureWeek = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)))

        let selected = WeekCalendar.selectedDate(
            whenMovingTo: futureWeek,
            direction: 1,
            calendar: calendar,
            now: now
        )

        #expect(calendar.isDate(selected, inSameDayAs: futureWeek))
    }

    @Test func movingToPastWeekSelectsSunday() throws {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))
        let pastWeek = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 10)))
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 16)))

        let selected = WeekCalendar.selectedDate(
            whenMovingTo: pastWeek,
            direction: -1,
            calendar: calendar,
            now: now
        )

        #expect(calendar.isDate(selected, inSameDayAs: sunday))
    }

    @Test func returningToCurrentWeekSelectsToday() throws {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 19)))
        let currentWeek = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))

        let selected = WeekCalendar.selectedDate(
            whenMovingTo: currentWeek,
            direction: 1,
            calendar: calendar,
            now: now
        )

        #expect(calendar.isDate(selected, inSameDayAs: now))
    }
}
