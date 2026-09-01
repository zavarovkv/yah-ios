import Foundation
import Testing
@testable import YetAnotherHabit

@MainActor
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

    @Test func dayKeyUsesStableGregorianComponents() throws {
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 24))
        )
        var buddhistCalendar = Calendar(identifier: .buddhist)
        buddhistCalendar.timeZone = calendar.timeZone

        #expect(WeekCalendar.dayKey(for: date, calendar: buddhistCalendar) == "2026-08-24")
        #expect(
            WeekCalendar.date(
                forDayKey: "2026-08-24",
                calendar: buddhistCalendar
            ) == date
        )
        #expect(WeekCalendar.date(forDayKey: "2026-02-31", calendar: calendar) == nil)
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

    @Test func monthGridStartsAtMondayColumnAndUsesStablePositions() throws {
        let august = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 15))
        )

        let cells = MonthGrid.cells(for: august, calendar: calendar)

        #expect(cells.count == 36)
        #expect(cells.map(\.id) == Array(0..<36))
        #expect(cells.prefix(5).allSatisfy { $0.date == nil })
        #expect(calendar.component(.day, from: try #require(cells[5].date)) == 1)
    }

    @Test func addingMonthsNormalizesAcrossYearBoundary() throws {
        let december = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 12, day: 18))
        )

        let january = MonthGrid.addingMonths(1, to: december, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: january)

        #expect(components == DateComponents(year: 2027, month: 1, day: 1))
    }

    @Test func habitStatusCanOnlyChangeTodayAndYesterday() throws {
        let today = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 23))
        )
        let yesterday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 22))
        )
        let twoDaysAgo = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 21))
        )
        let tomorrow = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 24))
        )

        #expect(HabitDayPolicy.canChangeStatus(on: today, today: today, calendar: calendar))
        #expect(HabitDayPolicy.canChangeStatus(on: yesterday, today: today, calendar: calendar))
        #expect(!HabitDayPolicy.canChangeStatus(on: twoDaysAgo, today: today, calendar: calendar))
        #expect(!HabitDayPolicy.canChangeStatus(on: tomorrow, today: today, calendar: calendar))
    }

    @Test func historicalHabitDaysStartTwoDaysBeforeToday() throws {
        let today = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 23))
        )
        let yesterday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 22))
        )
        let twoDaysAgo = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 21))
        )

        #expect(!HabitDayPolicy.isHistorical(today, today: today, calendar: calendar))
        #expect(!HabitDayPolicy.isHistorical(yesterday, today: today, calendar: calendar))
        #expect(HabitDayPolicy.isHistorical(twoDaysAgo, today: today, calendar: calendar))
    }
}
