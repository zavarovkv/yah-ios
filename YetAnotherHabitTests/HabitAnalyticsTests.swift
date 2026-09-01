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
    func pendingHabitShowsOnlyThePreviouslyCompletedStreak() throws {
        let monday = try date(year: 2026, month: 8, day: 24)
        let wednesday = try date(year: 2026, month: 8, day: 26)
        let friday = try date(year: 2026, month: 8, day: 28)
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0, 2, 4],
            createdAt: monday
        )
        let completedIdentifiers = Set([monday, wednesday].map {
            HabitCompletion.identifier(
                habitID: habit.identifier,
                dayKey: WeekCalendar.dayKey(for: $0, calendar: calendar)
            )
        })

        #expect(
            HabitStreakCalculator.streakBefore(
                friday,
                for: habit,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            ) == 2
        )
        #expect(
            HabitStreakCalculator.streak(
                for: habit,
                through: friday,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            ) == 0
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
    func presentationDataBuildsOneConsistentOptimisticSnapshot() {
        let state = AppDataState()
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: "2026-08-24"
        )
        state.recordCount(identifier: identifier, count: 1)

        let data = state.presentationData(
            persistedHabits: [habit],
            persistedCompletionCounts: [:]
        )

        #expect(data.habits.map(\.identifier) == [habit.identifier])
        #expect(data.completionCounts == [identifier: 1])
        #expect(data.completedIdentifiers == [identifier])

        state.recordDeleted(identifier: habit.identifier)
        let dataAfterDeletion = state.presentationData(
            persistedHabits: [habit],
            persistedCompletionCounts: [identifier: 1]
        )
        #expect(dataAfterDeletion.habits.isEmpty)
        #expect(dataAfterDeletion.completedIdentifiers.isEmpty)
    }

    @Test
    func completionMoveStateCancelsPendingTransitionsWithoutRetainingOverrides() {
        let state = HabitCompletionMoveState()
        let habitID = UUID()

        state.scheduleMove(
            for: habitID,
            previousCount: 0,
            reduceMotion: false
        )
        #expect(state.sectionCount(for: habitID, fallback: 1) == 0)
        #expect(state.successCount(for: habitID) == 0)

        state.cancelAll()

        #expect(state.sectionCount(for: habitID, fallback: 1) == 1)
        #expect(state.successCount(for: habitID) == nil)
        #expect(!state.hasDelayedSuccessCounts)
    }

    @Test
    func completionIndexScalesToLargeHistories() {
        let habits = (0..<400).map { index in
            Habit(
                name: "Habit \(index)",
                icon: "checkmark",
                color: "blue"
            )
        }
        var counts: [String: Int] = [:]
        counts.reserveCapacity(habits.count * 365)
        for habit in habits {
            for day in 0..<365 {
                counts["\(habit.identifier.uuidString)|day-\(day)"] = 1
            }
        }

        let clock = ContinuousClock()
        let start = clock.now
        let identifiers = HabitCompletionIndex.identifiers(
            in: counts,
            habits: habits
        )
        let elapsed = start.duration(to: clock.now)

        #expect(identifiers.count == counts.count)
        #expect(elapsed < .seconds(2))
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
        let emptyCompletion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-18",
            count: 0,
            habit: firstHabit
        )
        let otherCompletion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-17",
            habit: secondHabit
        )

        let counts = HabitCompletionIndex.counts(
            in: [firstCompletion, emptyCompletion, otherCompletion],
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
    func completionIndexTotalSaturatesInsteadOfOverflowing() {
        #expect(
            HabitCompletionIndex.totalCount(
                in: ["first": Int.max, "second": 1]
            ) == Int.max
        )
        #expect(
            HabitCompletionIndex.totalCount(
                in: ["positive": 4, "inactive": -3]
            ) == 4
        )
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
    func completedSectionMoveIsDetectedOnlyWhenGoalBecomesComplete() {
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

        #expect(HabitDaySorter.movesToCompletedSection(regularHabit, from: 0, to: 1))
        #expect(HabitDaySorter.movesToCompletedSection(targetCounter, from: 7, to: 8))
        #expect(!HabitDaySorter.movesToCompletedSection(targetCounter, from: 8, to: 9))
        #expect(!HabitDaySorter.movesToCompletedSection(openCounter, from: 0, to: 1))
    }

    @Test
    func cardVisualStateUsesStatusInsteadOfHabitColor() {
        let regularHabit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "purple"
        )
        let counter = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            kind: .counter,
            targetCount: 8
        )

        #expect(HabitCardVisualState(habit: regularHabit, isCompleted: false) == .pending)
        #expect(HabitCardVisualState(habit: counter, isCompleted: false) == .counter)
        #expect(HabitCardVisualState(habit: regularHabit, isCompleted: true) == .completed)
        #expect(HabitCardVisualState(habit: counter, isCompleted: true) == .completed)
    }

    @Test
    func daySectionsSeparatePendingOpenCountersAndCompletedHabits() throws {
        let day = try date(year: 2026, month: 8, day: 24)
        let regularPending = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            createdAt: day
        )
        let targetPending = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            createdAt: day,
            kind: .counter,
            targetCount: 8
        )
        let openCounter = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            createdAt: day,
            kind: .counter
        )
        let regularCompleted = Habit(
            name: "Разминка",
            icon: "figure.cooldown",
            color: "orange",
            createdAt: day
        )
        let targetCompleted = Habit(
            name: "Шаги",
            icon: "figure.walk",
            color: "green",
            createdAt: day,
            kind: .counter,
            targetCount: 10
        )
        let counts = [
            targetPending.identifier: 7,
            openCounter.identifier: 3,
            regularCompleted.identifier: 1,
            targetCompleted.identifier: 10
        ]

        let sections = HabitDaySorter.sections(
            in: [
                regularPending,
                targetPending,
                openCounter,
                regularCompleted,
                targetCompleted
            ],
            for: day,
            calendar: calendar
        ) { counts[$0.identifier, default: 0] }

        #expect(sections.pending.map(\.identifier) == [
            regularPending.identifier,
            targetPending.identifier
        ])
        #expect(sections.openCounters.map(\.identifier) == [openCounter.identifier])
        #expect(sections.completed.map(\.identifier) == [
            regularCompleted.identifier,
            targetCompleted.identifier
        ])
    }

    @Test
    func intervalCounterIsPendingOnlyOnItsLastScheduledDay() throws {
        let monday = try date(year: 2026, month: 8, day: 24)
        let wednesday = try date(year: 2026, month: 8, day: 26)
        let friday = try date(year: 2026, month: 8, day: 28)
        let counter = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            scheduledWeekdays: [0, 2, 4],
            createdAt: monday,
            kind: .counter,
            targetCount: 8,
            counterInterval: .weekly
        )

        let mondaySections = HabitDaySorter.sections(
            in: [counter],
            for: monday,
            calendar: calendar
        ) { _ in 3 }
        let wednesdaySections = HabitDaySorter.sections(
            in: [counter],
            for: wednesday,
            calendar: calendar
        ) { _ in 3 }
        let fridaySections = HabitDaySorter.sections(
            in: [counter],
            for: friday,
            calendar: calendar
        ) { _ in 3 }
        let completedEarlySections = HabitDaySorter.sections(
            in: [counter],
            for: wednesday,
            calendar: calendar
        ) { _ in 8 }

        #expect(mondaySections.openCounters.map(\.identifier) == [counter.identifier])
        #expect(wednesdaySections.openCounters.map(\.identifier) == [counter.identifier])
        #expect(fridaySections.pending.map(\.identifier) == [counter.identifier])
        #expect(completedEarlySections.completed.map(\.identifier) == [counter.identifier])
    }

    @Test
    func intervalGoalAffectsDailyProgressOnlyWhenItIsDue() throws {
        let monday = try date(year: 2026, month: 8, day: 24)
        let friday = try date(year: 2026, month: 8, day: 28)
        let counter = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            scheduledWeekdays: [0, 2, 4],
            createdAt: monday,
            kind: .counter,
            targetCount: 8,
            counterInterval: .weekly
        )
        let identifier = HabitCompletionPeriod.identifier(
            for: counter,
            containing: friday,
            calendar: calendar
        )

        let mondaySnapshot = HabitProgressCalculator.snapshot(
            for: [monday],
            habits: [counter],
            completedIdentifiers: [],
            calendar: calendar
        )
        let fridaySnapshot = HabitProgressCalculator.snapshot(
            for: [friday],
            habits: [counter],
            completedIdentifiers: [],
            calendar: calendar
        )

        #expect(mondaySnapshot.scheduledCount == 0)
        #expect(fridaySnapshot.scheduledCount == 1)
        #expect(
            HabitDaySorter.incompleteCount(
                in: [counter],
                for: monday,
                completionCounts: [:],
                calendar: calendar
            ) == 0
        )
        #expect(
            HabitDaySorter.incompleteCount(
                in: [counter],
                for: friday,
                completionCounts: [:],
                calendar: calendar
            ) == 1
        )
        #expect(
            HabitDailySuccessPolicy.shouldShowBanner(
                for: friday,
                habits: [counter],
                completionCounts: [identifier: 8],
                today: friday,
                calendar: calendar
            )
        )
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
        let completedSnapshot = HabitDailySuccessPolicy.snapshot(
            for: today,
            habits: [regularHabit, targetCounter, openCounter],
            completionCounts: completedCounts,
            today: today,
            calendar: calendar
        )

        #expect(completedSnapshot.completedCount == 2)
        #expect(completedSnapshot.goalCount == 2)
        #expect(completedSnapshot.isComplete)
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
        let incompleteSnapshot = HabitDailySuccessPolicy.snapshot(
            for: today,
            habits: [regularHabit, targetCounter, openCounter],
            completionCounts: incompleteCounts,
            today: today,
            calendar: calendar
        )
        #expect(incompleteSnapshot.completedCount == 1)
        #expect(incompleteSnapshot.goalCount == 2)
        #expect(!incompleteSnapshot.isComplete)
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

    @Test
    func weeklyCounterAnalyticsCountsCompletedIntervalsInsteadOfDays() throws {
        let firstMonday = try date(year: 2026, month: 8, day: 17)
        let secondMonday = try date(year: 2026, month: 8, day: 24)
        let secondWednesday = try date(year: 2026, month: 8, day: 26)
        let habit = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: "blue",
            createdAt: firstMonday,
            kind: .counter,
            targetCount: 8,
            counterInterval: .weekly
        )
        let identifiers = Set([firstMonday, secondMonday].map {
            HabitCompletionPeriod.identifier(
                for: habit,
                containing: $0,
                calendar: calendar
            )
        })

        let snapshot = HabitAnalyticsCalculator.snapshot(
            for: habit,
            completedIdentifiers: identifiers,
            through: secondWednesday,
            calendar: calendar
        )

        #expect(snapshot.currentStreak == 2)
        #expect(snapshot.bestStreak == 2)
        #expect(snapshot.completedCount == 2)
        #expect(snapshot.recentCompletedCount == 2)
        #expect(snapshot.recentScheduledCount == 2)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        )
    }
}
