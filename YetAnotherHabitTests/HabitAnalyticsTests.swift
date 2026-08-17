import Foundation
import Testing
@testable import YetAnotherHabit

@MainActor
struct HabitAnalyticsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test
    func streakSkipsDaysOutsideHabitSchedule() throws {
        let monday = try date(year: 2026, month: 8, day: 17)
        let nextMonday = try date(year: 2026, month: 8, day: 24)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0],
            createdAt: monday
        )
        let identifiers = Set([monday, nextMonday].map {
            HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: WeekCalendar.dayKey(for: $0, calendar: calendar)
            )
        })

        #expect(
            HabitStreakCalculator.streak(
                for: habit,
                through: nextMonday,
                completedIdentifiers: identifiers,
                calendar: calendar
            ) == 2
        )
    }

    @Test
    func streakStopsAtMissedScheduledOccurrence() throws {
        let firstMonday = try date(year: 2026, month: 8, day: 17)
        let thirdMonday = try date(year: 2026, month: 8, day: 31)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0],
            createdAt: firstMonday
        )
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: WeekCalendar.dayKey(for: thirdMonday, calendar: calendar)
        )

        #expect(
            HabitStreakCalculator.streak(
                for: habit,
                through: thirdMonday,
                completedIdentifiers: [identifier],
                calendar: calendar
            ) == 1
        )
    }

    @Test
    func progressCountsOnlyScheduledHabits() throws {
        let monday = try date(year: 2026, month: 8, day: 17)
        let daily = Habit(name: "Читать", icon: "book.fill", color: "blue", createdAt: monday)
        let tuesdayOnly = Habit(
            name: "Бегать",
            icon: "figure.run",
            color: "green",
            scheduledWeekdays: [1],
            createdAt: monday
        )
        let completed = HabitCompletion.identifier(
            habitID: daily.identifier,
            dayKey: WeekCalendar.dayKey(for: monday, calendar: calendar)
        )

        let snapshot = HabitProgressCalculator.snapshot(
            for: [monday],
            habits: [daily, tuesdayOnly],
            completedIdentifiers: [completed],
            calendar: calendar
        )

        #expect(snapshot.scheduledCount == 1)
        #expect(snapshot.completedCount == 1)
        #expect(snapshot.progress == 1)
    }

    @Test
    func appDataStateReconcilesSuccessfulOverrides() {
        let state = AppDataState()
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        state.recordAdded(habit)
        state.recordCompletion(identifier: "completion", isCompleted: true)

        state.reconcile(habits: [habit], completionIdentifiers: ["completion"])

        #expect(state.visibleHabits(from: [habit]).count == 1)
        #expect(state.visibleCompletionIdentifiers(from: ["completion"]) == ["completion"])
    }

    @Test
    func appDataStateHidesDeletedHabitUntilQueryUpdates() {
        let state = AppDataState()
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")

        state.recordDeleted(identifier: habit.identifier)
        state.reconcile(habits: [habit], completionIdentifiers: [])
        #expect(state.visibleHabits(from: [habit]).isEmpty)

        state.reconcile(habits: [], completionIdentifiers: [])
        #expect(state.visibleHabits(from: []).isEmpty)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        )
    }
}
