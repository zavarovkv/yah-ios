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
    func migratesExistingHabitsAndCompletionsToCounterSchema() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let storeURL = directoryURL.appendingPathComponent("Migration.store")

        do {
            let schema = Schema(versionedSchema: AppSchemaV1.self)
            let configuration = ModelConfiguration(
                "MigrationV1",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
            let context = ModelContext(container)
            let habit = AppSchemaV1.Habit(
                name: "Читать",
                icon: "book.fill",
                color: "blue"
            )
            context.insert(habit)
            context.insert(
                AppSchemaV1.HabitCompletion(
                    date: Date(timeIntervalSince1970: 1_700_000_000),
                    dayKey: "2023-11-14",
                    habit: habit
                )
            )
            try context.save()
        }

        let schema = Schema(versionedSchema: AppSchemaV3.self)
        let configuration = ModelConfiguration(
            "MigrationV3",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let habit = try #require(context.fetch(FetchDescriptor<Habit>()).first)
        let completion = try #require(
            context.fetch(FetchDescriptor<HabitCompletion>()).first
        )

        #expect(habit.name == "Читать")
        #expect(habit.kind == .habit)
        #expect(habit.targetCount == nil)
        #expect(completion.count == 1)
        #expect(completion.habit?.identifier == habit.identifier)
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

        try HabitCompletionStore.setCount(
            1,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )
        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).count == 1)

        try HabitCompletionStore.setCount(
            0,
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

        try HabitCompletionStore.setCount(
            1,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )

        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).count == 1)
    }

    @Test
    func completingHabitRepairsInactiveCanonicalRecord() throws {
        let container = try makeContainer()
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))
        )
        let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        let completion = HabitCompletion(
            date: date,
            dayKey: dayKey,
            isCompleted: false,
            habit: habit
        )
        context.insert(habit)
        context.insert(completion)
        try context.save()

        try HabitCompletionStore.setCount(
            1,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )

        let storedCompletion = try #require(
            context.fetch(FetchDescriptor<HabitCompletion>()).first
        )
        #expect(storedCompletion.isCompleted)
        #expect(storedCompletion.dayKey == dayKey)
        #expect(storedCompletion.date == calendar.startOfDay(for: date))
        #expect(storedCompletion.count == 1)
    }

    @Test
    func counterValueCanBeChangedAndReset() throws {
        let container = try makeContainer()
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))
        )
        let habit = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            kind: .counter
        )
        context.insert(habit)
        try context.save()

        try HabitCompletionStore.setCount(
            3,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )

        var completion = try #require(
            context.fetch(FetchDescriptor<HabitCompletion>()).first
        )
        #expect(completion.count == 3)
        #expect(completion.isCompleted)

        try HabitCompletionStore.setCount(
            5,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )
        completion = try #require(
            context.fetch(FetchDescriptor<HabitCompletion>()).first
        )
        #expect(completion.count == 5)

        try HabitCompletionStore.setCount(
            0,
            habit: habit,
            date: date,
            calendar: calendar,
            context: context
        )
        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).isEmpty)
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

        try DataMaintenance.reconcile(
            context: context,
            calendar: .current,
            locale: Locale(identifier: "en")
        )

        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        #expect(completions.count == 1)
        #expect(!completions[0].dayKey.isEmpty)
        #expect(!completions[0].identifier.isEmpty)
    }

    @Test
    func maintenanceKeepsLargestCounterValueWhenRepairingDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let habit = Habit(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            color: "brown",
            kind: .counter
        )
        let date = Date(timeIntervalSince1970: 1_787_000_000)
        context.insert(habit)
        context.insert(HabitCompletion(date: date, dayKey: "", count: 2, habit: habit))
        context.insert(HabitCompletion(date: date, dayKey: "", count: 4, habit: habit))
        try context.save()

        try DataMaintenance.reconcile(
            context: context,
            calendar: .current,
            locale: Locale(identifier: "en")
        )

        let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
        #expect(completions.count == 1)
        #expect(completions[0].count == 4)
    }

    @Test
    func maintenanceRemovesInactiveCompletionRecords() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let habit = Habit(name: "Читать", icon: "book.fill", color: "blue")
        context.insert(habit)
        context.insert(
            HabitCompletion(
                date: .now,
                dayKey: "2026-08-17",
                isCompleted: false,
                habit: habit
            )
        )
        try context.save()

        try DataMaintenance.reconcile(
            context: context,
            calendar: .current,
            locale: Locale(identifier: "en")
        )

        #expect(try context.fetch(FetchDescriptor<HabitCompletion>()).isEmpty)
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

        let primary = UserProfileReconciler.reconcile(
            [older, newer],
            in: context,
            locale: Locale(identifier: "en")
        )
        try context.save()

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(primary?.name == "Имя")
        #expect(primary?.avatarData == Data([1, 2, 3]))
    }

    @Test
    func profileReconciliationGeneratesNameWhenAllNamesAreEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = UserProfile(name: "   ")
        context.insert(profile)

        let primary = UserProfileReconciler.reconcile(
            [profile],
            in: context,
            locale: Locale(identifier: "en")
        )

        #expect(primary?.name.isEmpty == false)
    }

    @Test
    func generatedProfileNameUsesRequestedLocale() {
        let localizedNames: [(locale: String, names: Set<String>)] = [
            (
                "en",
                [
                    "Cheerful Badger", "Kind Llama", "Nimble Fox",
                    "Curious Panda", "Brave Otter", "Quiet Raccoon",
                ]
            ),
            (
                "es",
                [
                    "Tejón alegre", "Llama amable", "Zorro ágil",
                    "Panda curioso", "Nutria valiente", "Mapache tranquilo",
                ]
            ),
            (
                "fr",
                [
                    "Blaireau joyeux", "Lama bienveillant", "Renard agile",
                    "Panda curieux", "Loutre courageuse", "Raton laveur tranquille",
                ]
            ),
            (
                "pt-BR",
                [
                    "Texugo alegre", "Lhama gentil", "Raposa ágil",
                    "Panda curioso", "Lontra corajosa", "Guaxinim tranquilo",
                ]
            ),
        ]

        for localization in localizedNames {
            let name = UserProfileReconciler.generatedName(
                locale: Locale(identifier: localization.locale)
            )

            #expect(localization.names.contains(name))
        }
    }

    @Test
    func programmaticLocalizationUsesRequestedLocale() {
        let localizedToday = [
            "en": "Today",
            "es": "Hoy",
            "fr": "Aujourd’hui",
            "pt-BR": "Hoje",
            "ru": "Сегодня",
        ]

        for (localeIdentifier, expectedValue) in localizedToday {
            #expect(
                AppLocalization.string(
                    "Сегодня",
                    locale: Locale(identifier: localeIdentifier)
                ) == expectedValue
            )
        }
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
        let schema = Schema(versionedSchema: AppSchemaV3.self)
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
