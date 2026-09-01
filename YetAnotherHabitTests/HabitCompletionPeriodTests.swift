import Foundation
import Testing
@testable import YetAnotherHabit

@MainActor
struct HabitCompletionPeriodTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test
    func intervalsResetAtTheirCalendarBoundaries() throws {
        let monday = try date(year: 2026, month: 8, day: 17)
        let sunday = try date(year: 2026, month: 8, day: 23)
        let nextMonday = try date(year: 2026, month: 8, day: 24)
        let september = try date(year: 2026, month: 9, day: 1)
        let nextYear = try date(year: 2027, month: 1, day: 1)

        let daily = counter(interval: .daily)
        #expect(key(for: daily, on: monday) != key(for: daily, on: sunday))

        let weekly = counter(interval: .weekly)
        #expect(key(for: weekly, on: monday) == key(for: weekly, on: sunday))
        #expect(key(for: weekly, on: sunday) != key(for: weekly, on: nextMonday))

        let biweekly = counter(interval: .biweekly, createdAt: monday)
        #expect(key(for: biweekly, on: monday) == key(for: biweekly, on: nextMonday))
        let thirdMonday = try date(year: 2026, month: 8, day: 31)
        #expect(key(for: biweekly, on: nextMonday) != key(for: biweekly, on: thirdMonday))

        let monthly = counter(interval: .monthly)
        #expect(key(for: monthly, on: monday) == key(for: monthly, on: sunday))
        #expect(key(for: monthly, on: sunday) != key(for: monthly, on: september))

        let yearly = counter(interval: .yearly)
        #expect(key(for: yearly, on: monday) == key(for: yearly, on: september))
        #expect(key(for: yearly, on: september) != key(for: yearly, on: nextYear))
    }

    @Test
    func regularHabitAlwaysUsesDailyBuckets() throws {
        let monday = try date(year: 2026, month: 8, day: 17)
        let tuesday = try date(year: 2026, month: 8, day: 18)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            counterInterval: .weekly
        )

        #expect(habit.effectiveCounterInterval == .daily)
        #expect(key(for: habit, on: monday) != key(for: habit, on: tuesday))
    }

    @Test
    func goalIsDueOnTheLastScheduledOccurrenceOfTheInterval() throws {
        let monday = try date(year: 2026, month: 8, day: 24)
        let wednesday = try date(year: 2026, month: 8, day: 26)
        let friday = try date(year: 2026, month: 8, day: 28)
        let sunday = try date(year: 2026, month: 8, day: 30)
        let augustLastDay = try date(year: 2026, month: 8, day: 31)
        let decemberLastDay = try date(year: 2026, month: 12, day: 31)
        let weekly = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            scheduledWeekdays: [0, 2, 4],
            createdAt: monday,
            kind: .counter,
            targetCount: 8,
            counterInterval: .weekly
        )
        let monthly = Habit(
            name: "Тренировки",
            icon: "figure.run",
            color: "green",
            createdAt: monday,
            kind: .counter,
            targetCount: 20,
            counterInterval: .monthly
        )
        let yearly = Habit(
            name: "Книги",
            icon: "book.fill",
            color: "orange",
            createdAt: monday,
            kind: .counter,
            targetCount: 50,
            counterInterval: .yearly
        )

        #expect(!HabitCompletionPeriod.isGoalDue(for: weekly, on: monday, calendar: calendar))
        #expect(!HabitCompletionPeriod.isGoalDue(for: weekly, on: wednesday, calendar: calendar))
        #expect(HabitCompletionPeriod.isGoalDue(for: weekly, on: friday, calendar: calendar))
        #expect(!HabitCompletionPeriod.isGoalDue(for: weekly, on: sunday, calendar: calendar))
        #expect(
            HabitCompletionPeriod.isGoalDue(
                for: monthly,
                on: augustLastDay,
                calendar: calendar
            )
        )
        #expect(
            HabitCompletionPeriod.isGoalDue(
                for: yearly,
                on: decemberLastDay,
                calendar: calendar
            )
        )
    }

    private func counter(interval: CounterInterval, createdAt: Date = .now) -> Habit {
        Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: createdAt,
            kind: .counter,
            counterInterval: interval
        )
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        )
    }

    private func key(for habit: Habit, on date: Date) -> String {
        HabitCompletionPeriod.key(for: habit, containing: date, calendar: calendar)
    }
}
