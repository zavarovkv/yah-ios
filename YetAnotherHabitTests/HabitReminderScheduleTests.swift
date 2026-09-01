import Foundation
import Testing
@testable import YetAnotherHabit

@MainActor
struct HabitReminderScheduleTests {
    @Test
    func entriesNormalizeWeekdaysAndUseFoundationWeekdayValues() {
        let habitID = UUID(uuidString: "34F9D884-A19E-42DB-A792-9B24BC6E664C")!

        let entries = HabitReminderSchedule.entries(
            habitID: habitID,
            scheduledWeekdays: [6, 0, 2, 2, -1, 7],
            hour: 8,
            minute: 30
        )

        #expect(entries.map(\.weekday) == [2, 4, 1])
        #expect(entries.map(\.hour) == [8, 8, 8])
        #expect(entries.map(\.minute) == [30, 30, 30])
        #expect(
            entries.map(\.identifier) == [
                "habit-reminder.34F9D884-A19E-42DB-A792-9B24BC6E664C.0",
                "habit-reminder.34F9D884-A19E-42DB-A792-9B24BC6E664C.2",
                "habit-reminder.34F9D884-A19E-42DB-A792-9B24BC6E664C.6"
            ]
        )
    }

    @Test
    func invalidTimeProducesNoScheduleEntries() {
        let habitID = UUID()

        #expect(
            HabitReminderSchedule.entries(
                habitID: habitID,
                scheduledWeekdays: [0],
                hour: 24,
                minute: 0
            ).isEmpty
        )
        #expect(
            HabitReminderSchedule.entries(
                habitID: habitID,
                scheduledWeekdays: [0],
                hour: 9,
                minute: -1
            ).isEmpty
        )
    }

    @Test
    func identifiersCoverEveryPossibleWeekday() {
        let habitID = UUID(uuidString: "34F9D884-A19E-42DB-A792-9B24BC6E664C")!

        let identifiers = HabitReminderSchedule.identifiers(for: habitID)

        #expect(identifiers.count == 7)
        #expect(Set(identifiers).count == 7)
        #expect(identifiers.first?.hasSuffix(".0") == true)
        #expect(identifiers.last?.hasSuffix(".6") == true)
    }
}
