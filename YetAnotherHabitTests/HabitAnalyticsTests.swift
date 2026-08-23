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
    func dailyProgressIgnoresCountersWithoutGoals() throws {
        let monday = try date(year: 2026, month: 8, day: 17)
        let regularHabit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            createdAt: monday
        )
        let openCounter = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: monday,
            kind: .counter
        )
        let completed = HabitCompletion.identifier(
            habitID: regularHabit.identifier,
            dayKey: WeekCalendar.dayKey(for: monday, calendar: calendar)
        )

        let snapshot = HabitProgressCalculator.snapshot(
            for: [monday],
            habits: [regularHabit, openCounter],
            completedIdentifiers: [completed],
            calendar: calendar
        )

        #expect(snapshot.scheduledCount == 1)
        #expect(snapshot.completedCount == 1)
        #expect(snapshot.progress == 1)
        #expect(
            HabitProgressCalculator.progress(
                for: monday,
                habits: [openCounter],
                completedIdentifiers: [],
                calendar: calendar
            ) == nil
        )
        #expect(
            HabitDaySorter.incompleteCount(
                in: [openCounter],
                for: monday,
                completionCounts: [:],
                calendar: calendar
            ) == 0
        )
    }

    @Test
    func analyticsSnapshotUsesScheduledOccurrencesForStreaksAndRecentProgress() throws {
        let firstMonday = try date(year: 2026, month: 8, day: 3)
        let secondMonday = try date(year: 2026, month: 8, day: 10)
        let fourthMonday = try date(year: 2026, month: 8, day: 24)
        let fifthMonday = try date(year: 2026, month: 8, day: 31)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0],
            createdAt: firstMonday
        )
        let identifiers = Set([firstMonday, secondMonday, fourthMonday, fifthMonday].map {
            HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: WeekCalendar.dayKey(for: $0, calendar: calendar)
            )
        })

        let snapshot = HabitAnalyticsCalculator.snapshot(
            for: habit,
            completedIdentifiers: identifiers,
            through: fifthMonday,
            recentDayCount: 15,
            calendar: calendar
        )

        #expect(snapshot.currentStreak == 2)
        #expect(snapshot.bestStreak == 2)
        #expect(snapshot.completedCount == 4)
        #expect(snapshot.recentCompletedCount == 2)
        #expect(snapshot.recentScheduledCount == 3)
        #expect(snapshot.recentProgress == 2.0 / 3.0)
    }

    @Test
    func analyticsDayStatusRespectsCreationScheduleAndToday() throws {
        let previousMonday = try date(year: 2026, month: 8, day: 10)
        let monday = try date(year: 2026, month: 8, day: 17)
        let tuesday = try date(year: 2026, month: 8, day: 18)
        let nextMonday = try date(year: 2026, month: 8, day: 24)
        let futureMonday = try date(year: 2026, month: 8, day: 31)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0],
            createdAt: monday
        )

        #expect(
            HabitAnalyticsCalculator.status(
                for: previousMonday,
                habit: habit,
                completedIdentifiers: [],
                today: nextMonday,
                calendar: calendar
            ) == .unavailable
        )
        #expect(
            HabitAnalyticsCalculator.status(
                for: tuesday,
                habit: habit,
                completedIdentifiers: [],
                today: nextMonday,
                calendar: calendar
            ) == .unscheduled
        )
        #expect(
            HabitAnalyticsCalculator.status(
                for: monday,
                habit: habit,
                completedIdentifiers: [],
                today: nextMonday,
                calendar: calendar
            ) == .missed
        )
        #expect(
            HabitAnalyticsCalculator.status(
                for: nextMonday,
                habit: habit,
                completedIdentifiers: [],
                today: nextMonday,
                calendar: calendar
            ) == .pending
        )
        #expect(
            HabitAnalyticsCalculator.status(
                for: futureMonday,
                habit: habit,
                completedIdentifiers: [],
                today: nextMonday,
                calendar: calendar
            ) == .upcoming
        )
    }

    @Test
    func appDataStateReconcilesSuccessfulOverrides() {
        let state = AppDataState()
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        state.recordAdded(habit)
        state.recordCount(identifier: "completion", count: 1)

        state.reconcile(habits: [habit], completionCounts: ["completion": 1])

        #expect(state.visibleHabits(from: [habit]).count == 1)
        #expect(state.visibleCompletionCounts(from: ["completion": 1]) == ["completion": 1])
    }

    @Test
    func appDataStateHidesDeletedHabitUntilQueryUpdates() {
        let state = AppDataState()
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")

        state.recordDeleted(identifier: habit.identifier)
        state.reconcile(habits: [habit], completionCounts: [:])
        #expect(state.visibleHabits(from: [habit]).isEmpty)

        state.reconcile(habits: [], completionCounts: [:])
        #expect(state.visibleHabits(from: []).isEmpty)
    }

    @Test
    func optimisticCounterValueRespectsTargetWhenBuildingCompletionIndex() {
        let state = AppDataState()
        let habit = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            kind: .counter,
            targetCount: 8
        )
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: "2026-08-17"
        )

        state.recordCount(identifier: identifier, count: 7)
        var counts = state.visibleCompletionCounts(from: [:])
        #expect(
            HabitCompletionIndex.identifiers(in: counts, habits: [habit]).isEmpty
        )

        state.recordCount(identifier: identifier, count: 8)
        counts = state.visibleCompletionCounts(from: [:])
        #expect(
            HabitCompletionIndex.identifiers(in: counts, habits: [habit]) == [identifier]
        )
    }

    @Test
    func completionIndexIncludesOnlyCompletedRecordsForRequestedHabit() {
        let firstHabit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        let secondHabit = Habit(name: "Бегать", icon: "figure.run", color: "green")
        let firstCompletion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-17",
            habit: firstHabit
        )
        let inactiveCompletion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-18",
            isCompleted: false,
            habit: firstHabit
        )
        let otherCompletion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-17",
            habit: secondHabit
        )

        let counts = HabitCompletionIndex.counts(
            in: [firstCompletion, inactiveCompletion, otherCompletion],
            for: firstHabit.identifier
        )
        let identifiers = HabitCompletionIndex.identifiers(
            in: counts,
            habits: [firstHabit]
        )

        #expect(identifiers == [firstCompletion.identifier])
    }

    @Test
    func completionIndexKeepsCounterValue() {
        let habit = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            kind: .counter
        )
        let completion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-17",
            count: 3,
            habit: habit
        )

        let counts = HabitCompletionIndex.counts(in: [completion])

        #expect(counts[completion.identifier] == 3)
    }

    @Test
    func counterWithTargetCompletesOnlyAfterReachingGoal() {
        let habit = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            kind: .counter,
            targetCount: 8
        )
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: "2026-08-17"
        )

        #expect(
            HabitCompletionIndex.identifiers(
                in: [identifier: 7],
                habits: [habit]
            ).isEmpty
        )
        #expect(
            HabitCompletionIndex.identifiers(
                in: [identifier: 9],
                habits: [habit]
            ) == [identifier]
        )
    }

    @Test
    func completedSectionIncludesOnlyCountersThatReachedAnExplicitTarget() {
        let regularHabit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue"
        )
        let targetCounter = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            kind: .counter,
            targetCount: 8
        )
        let openCounter = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            kind: .counter
        )

        #expect(HabitDaySorter.belongsToCompletedSection(regularHabit, count: 1))
        #expect(!HabitDaySorter.belongsToCompletedSection(targetCounter, count: 7))
        #expect(HabitDaySorter.belongsToCompletedSection(targetCounter, count: 8))
        #expect(HabitDaySorter.belongsToCompletedSection(targetCounter, count: 12))
        #expect(!HabitDaySorter.belongsToCompletedSection(openCounter, count: 3))
    }

    @Test
    func daySorterKeepsIncompleteHabitsFirstAndCountersLast() throws {
        let day = try date(year: 2026, month: 8, day: 17)
        let completed = Habit(
            name: "Выполнено",
            icon: "checkmark",
            color: "green",
            createdAt: day
        )
        let incomplete = Habit(
            name: "Не выполнено",
            icon: "book.fill",
            color: "blue",
            createdAt: day.addingTimeInterval(60)
        )
        let counter = Habit(
            name: "Счётчик",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: day,
            kind: .counter
        )
        let completedIdentifier = HabitCompletion.identifier(
            habitID: completed.identifier,
            dayKey: WeekCalendar.dayKey(for: day, calendar: calendar)
        )

        let sorted = HabitDaySorter.sorted(
            [counter, completed, incomplete],
            for: day,
            completionCounts: [completedIdentifier: 1],
            calendar: calendar
        )

        #expect(sorted.map(\.identifier) == [
            incomplete.identifier,
            completed.identifier,
            counter.identifier
        ])
        #expect(
            HabitDaySorter.incompleteCount(
                in: [completed, incomplete, counter],
                for: day,
                completionCounts: [completedIdentifier: 1],
                calendar: calendar
            ) == 1
        )
    }

    @Test
    func daySorterTreatsTargetCountersLikeRegularHabits() throws {
        let day = try date(year: 2026, month: 8, day: 17)
        let targetPending = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            createdAt: day,
            kind: .counter,
            targetCount: 8
        )
        let regularPending = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            createdAt: day.addingTimeInterval(60)
        )
        let targetCompleted = Habit(
            name: "Шаги",
            icon: "figure.walk",
            color: "green",
            createdAt: day,
            kind: .counter,
            targetCount: 10
        )
        let regularCompleted = Habit(
            name: "Разминка",
            icon: "figure.cooldown",
            color: "orange",
            createdAt: day.addingTimeInterval(60)
        )
        let openCounter = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: day.addingTimeInterval(-60),
            kind: .counter
        )
        let dayKey = WeekCalendar.dayKey(for: day, calendar: calendar)
        let counts = [
            HabitCompletion.identifier(habitID: targetPending.identifier, dayKey: dayKey): 7,
            HabitCompletion.identifier(habitID: targetCompleted.identifier, dayKey: dayKey): 10,
            HabitCompletion.identifier(habitID: regularCompleted.identifier, dayKey: dayKey): 1
        ]

        let sorted = HabitDaySorter.sorted(
            [openCounter, regularCompleted, targetCompleted, regularPending, targetPending],
            for: day,
            completionCounts: counts,
            calendar: calendar
        )

        #expect(sorted.map(\.identifier) == [
            targetPending.identifier,
            regularPending.identifier,
            targetCompleted.identifier,
            regularCompleted.identifier,
            openCounter.identifier
        ])
    }

    @Test
    func dailySuccessRequiresEveryMeasurableGoalAndIgnoresOpenCounters() throws {
        let today = try date(year: 2026, month: 8, day: 20)
        let regularHabit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            createdAt: today
        )
        let targetCounter = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            createdAt: today,
            kind: .counter,
            targetCount: 8
        )
        let openCounter = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: today,
            kind: .counter
        )
        let dayKey = WeekCalendar.dayKey(for: today, calendar: calendar)
        let completedCounts = [
            HabitCompletion.identifier(habitID: regularHabit.identifier, dayKey: dayKey): 1,
            HabitCompletion.identifier(habitID: targetCounter.identifier, dayKey: dayKey): 8
        ]

        #expect(
            HabitDailySuccessPolicy.shouldShowBanner(
                for: today,
                habits: [regularHabit, targetCounter, openCounter],
                completionCounts: completedCounts,
                today: today,
                calendar: calendar
            )
        )

        var incompleteCounts = completedCounts
        incompleteCounts[
            HabitCompletion.identifier(habitID: targetCounter.identifier, dayKey: dayKey)
        ] = 7
        #expect(
            !HabitDailySuccessPolicy.shouldShowBanner(
                for: today,
                habits: [regularHabit, targetCounter, openCounter],
                completionCounts: incompleteCounts,
                today: today,
                calendar: calendar
            )
        )
        #expect(
            !HabitDailySuccessPolicy.shouldShowBanner(
                for: today,
                habits: [openCounter],
                completionCounts: [:],
                today: today,
                calendar: calendar
            )
        )
    }

    @Test
    func dailySuccessIsAvailableOnlyForTodayAndYesterday() throws {
        let today = try date(year: 2026, month: 8, day: 20)
        let yesterday = try date(year: 2026, month: 8, day: 19)
        let earlierDay = try date(year: 2026, month: 8, day: 18)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            createdAt: earlierDay
        )
        let counts = [today, yesterday, earlierDay].reduce(into: [String: Int]()) {
            result, date in
            let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
            result[
                HabitCompletion.identifier(habitID: habit.identifier, dayKey: dayKey)
            ] = 1
        }

        #expect(
            HabitDailySuccessPolicy.shouldShowBanner(
                for: today,
                habits: [habit],
                completionCounts: counts,
                today: today,
                calendar: calendar
            )
        )
        #expect(
            HabitDailySuccessPolicy.shouldShowBanner(
                for: yesterday,
                habits: [habit],
                completionCounts: counts,
                today: today,
                calendar: calendar
            )
        )
        #expect(
            !HabitDailySuccessPolicy.shouldShowBanner(
                for: earlierDay,
                habits: [habit],
                completionCounts: counts,
                today: today,
                calendar: calendar
            )
        )
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        )
    }
}
