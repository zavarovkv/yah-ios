import Foundation
import Testing
import UIKit
@testable import YetAnotherHabit

@MainActor
struct HabitDraftTests {
    @Test
    func draftNormalizesInputWhenCreatingHabit() {
        let createdAt = Date(timeIntervalSince1970: 1_787_000_000)
        let draft = HabitDraft(
            kind: .counter,
            name: "  Читать  ",
            icon: "book.fill",
            color: .green,
            scheduledWeekdays: [4, 0, 2, -1, 7]
        )

        let habit = draft.makeHabit(createdAt: createdAt)

        #expect(habit.name == "Читать")
        #expect(habit.icon == "book.fill")
        #expect(habit.color == HabitColor.green.rawValue)
        #expect(habit.scheduledWeekdays == [0, 2, 4])
        #expect(habit.createdAt == createdAt)
        #expect(habit.kind == .counter)
    }

    @Test
    func draftRequiresNameAndAtLeastOneScheduledDay() {
        #expect(!HabitDraft(name: "   ").isValid)
        #expect(!HabitDraft(name: "Читать", scheduledWeekdays: []).isValid)
        #expect(HabitDraft(name: "Читать", scheduledWeekdays: [0]).isValid)
    }

    @Test
    func draftAppliesAllEditableFields() {
        let habit = Habit(name: "Старое", icon: "checkmark", color: "blue")
        let draft = HabitDraft(
            kind: .counter,
            name: "Новое",
            icon: "figure.run",
            color: .orange,
            scheduledWeekdays: [1, 3]
        )

        draft.apply(to: habit)

        #expect(habit.name == "Новое")
        #expect(habit.icon == "figure.run")
        #expect(habit.color == HabitColor.orange.rawValue)
        #expect(habit.scheduledWeekdays == [1, 3])
        #expect(habit.kind == .counter)
    }

    @Test
    func counterTargetIsOptionalAndDoesNotApplyToRegularHabit() {
        let counter = HabitDraft(
            kind: .counter,
            name: "Вода",
            targetCount: 8
        ).makeHabit(createdAt: .now)
        let regular = HabitDraft(
            kind: .habit,
            name: "Читать",
            targetCount: 8
        ).makeHabit(createdAt: .now)

        #expect(counter.effectiveTargetCount == 8)
        #expect(counter.isGoalMet(by: 8))
        #expect(!counter.isGoalMet(by: 7))
        #expect(regular.effectiveTargetCount == nil)
    }

    @Test
    func randomizedDraftUsesSupportedAppearance() {
        let draft = HabitDraft.randomized()

        #expect(HabitAppearanceOptions.icons.contains(draft.icon))
        #expect(HabitColor.allCases.contains(draft.color))
    }

    @Test
    func appearanceOptionsAreUniqueAndUseAvailableSystemSymbols() {
        #expect(Set(HabitAppearanceOptions.icons).count == HabitAppearanceOptions.icons.count)
        #expect(
            HabitAppearanceOptions.icons.count.isMultiple(
                of: HabitAppearanceOptions.iconsPerPage
            )
        )
        #expect(
            HabitColor.allCases.count.isMultiple(
                of: HabitAppearanceOptions.colorsPerPage
            )
        )
        #expect(HabitAppearanceOptions.icons.count == 96)
        #expect(HabitColor.allCases.count == 24)

        for icon in HabitAppearanceOptions.icons {
            #expect(UIImage(systemName: icon) != nil)
        }
    }
}
