import Foundation
import SwiftData
import Testing
@testable import YetAnotherHabit

@MainActor
struct PersistenceTests {
    @Test
    func savesAndFetchesHabit() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue"
        )

        context.insert(habit)
        try context.save()

        let habits = try context.fetch(FetchDescriptor<Habit>())
        #expect(habits.count == 1)
        #expect(habits.first?.name == "Читать")
    }

    @Test
    func addingHabitKeepsExistingHabits() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let firstHabit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        context.insert(firstHabit)
        try context.save()

        let secondHabit = Habit(name: "Бегать", icon: "figure.run", color: "green")
        context.insert(secondHabit)
        try context.save()

        let habits = try context.fetch(FetchDescriptor<Habit>())
        #expect(habits.count == 2)
        #expect(Set(habits.map(\.name)) == ["Читать", "Бегать"])
    }

    @Test
    func completionCanBeAddedAndRemovedAfterQueryWouldBeStale() throws {
        let container = try makeContainer()
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))
        )
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        context.insert(habit)
        try context.save()

        try HabitCompletionStore.setCompleted(
            true,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )
        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).count == 1)

        try HabitCompletionStore.setCompleted(
            false,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )
        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).isEmpty)
    }

    @Test
    func completingHabitIsIdempotentAndRepairsDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))
        )
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        context.insert(habit)
        context.insert(HabitCompletion(date: date, dayKey: dayKey, habit: habit))
        context.insert(HabitCompletion(date: date, dayKey: dayKey, habit: habit))
        try context.save()

        try HabitCompletionStore.setCompleted(
            true,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )

        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).count == 1)
    }

    @Test
    func savesAndFetchesUserProfile() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(UserProfile(name: "Константин"))
        try context.save()

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles.first?.name == "Константин")
    }

    @Test
    func deletingHabitDeletesItsCompletions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        let completion = HabitCompletion(
            date: .now,
            dayKey: "2026-08-17",
            habit: habit
        )
        context.insert(habit)
        context.insert(completion)
        try context.save()

        context.delete(habit)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Habit>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).isEmpty)
    }

    @Test
    func maintenanceRemovesDuplicateCompletions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        let date = Date(timeIntervalSince1970: 1_787_000_000)
        context.insert(habit)
        context.insert(HabitCompletion(date: date, dayKey: "", habit: habit))
        context.insert(HabitCompletion(date: date, dayKey: "", habit: habit))
        try context.save()

        try DataMaintenance.reconcile(context: context, calendar: .current)

        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        #expect(completions.count == 1)
        #expect(!completions[0].dayKey.isEmpty)
        #expect(!completions[0].identifier.isEmpty)
    }

    @Test
    func profileReconciliationKeepsNewestAndMergesMissingData() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let older = UserProfile(name: "Имя", avatarData: Data([1, 2, 3]))
        older.updatedAt = .distantPast
        let newer = UserProfile(name: "")
        newer.updatedAt = .now
        context.insert(older)
        context.insert(newer)
        try context.save()

        let primary = UserProfileReconciler.reconcile([older, newer], in: context)
        try context.save()

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(primary?.name == "Имя")
        #expect(primary?.avatarData == Data([1, 2, 3]))
    }

    @Test
    func habitScheduleRespectsWeekdayAndStartDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))
        )
        let tuesday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 18))
        )
        let previousMonday = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))
        )
        let habit = Habit(
            name: "Читать",
            icon: "book.fill",
            color: "blue",
            scheduledWeekdays: [0],
            createdAt: monday
        )

        #expect(habit.isScheduled(on: monday, calendar: calendar))
        #expect(!habit.isScheduled(on: tuesday, calendar: calendar))
        #expect(!habit.isScheduled(on: previousMonday, calendar: calendar))
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: AppSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: configuration
        )
    }
}
