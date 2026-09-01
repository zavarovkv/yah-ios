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
            scheduledWeekdays: [4, 0, 2, -1, 7],
            counterInterval: .monthly
        )

        let habit = draft.makeHabit(createdAt: createdAt)

        #expect(habit.name == "Читать")
        #expect(habit.icon == "book.fill")
        #expect(habit.color == HabitColor.green.rawValue)
        #expect(habit.scheduledWeekdays == [0, 2, 4])
        #expect(habit.createdAt == createdAt)
        #expect(habit.kind == .counter)
        #expect(habit.effectiveCounterInterval == .monthly)
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
            scheduledWeekdays: [1, 3],
            counterInterval: .weekly
        )

        draft.apply(to: habit)

        #expect(habit.name == "Новое")
        #expect(habit.icon == "figure.run")
        #expect(habit.color == HabitColor.orange.rawValue)
        #expect(habit.scheduledWeekdays == [1, 3])
        #expect(habit.kind == .counter)
        #expect(habit.effectiveCounterInterval == .weekly)
    }

    @Test
    func draftPersistsAndClearsReminderTime() {
        var draft = HabitDraft(
            name: "Читать",
            scheduledWeekdays: [0, 2, 4],
            reminderHour: 8,
            reminderMinute: 30
        )

        let habit = draft.makeHabit(createdAt: .now)

        #expect(habit.reminderComponents == DateComponents(hour: 8, minute: 30))
        #expect(!draft.changesReminder(of: habit))

        draft.setReminder(hour: 21, minute: 15)
        #expect(draft.changesReminder(of: habit))
        draft.apply(to: habit)
        #expect(habit.reminderComponents == DateComponents(hour: 21, minute: 15))

        draft.setReminder(hour: nil, minute: nil)
        draft.apply(to: habit)
        #expect(habit.reminderComponents == nil)
    }

    @Test
    func draftRejectsIncompleteOrOutOfRangeReminderTime() {
        var draft = HabitDraft(name: "Читать")

        draft.setReminder(hour: 9, minute: nil)
        #expect(!draft.hasReminder)

        draft.setReminder(hour: 24, minute: 0)
        #expect(!draft.hasReminder)

        draft.setReminder(hour: 23, minute: 59)
        #expect(draft.hasReminder)
    }

    @Test
    func draftDistinguishesCosmeticEditsFromHistoricalRuleChanges() {
        let habit = Habit(
            name: "Вода",
            icon: "drop.fill",
            color: HabitColor.blue.rawValue,
            scheduledWeekdays: [0, 2, 4],
            kind: .counter,
            targetCount: 8,
            counterInterval: .daily
        )

        var draft = HabitDraft(habit: habit)
        draft.name = "Стаканы воды"
        draft.icon = "waterbottle.fill"
        draft.color = .cyan
        #expect(!draft.changesHistoricalRules(of: habit))

        draft.scheduledWeekdays = [1, 3, 5]
        #expect(draft.changesHistoricalRules(of: habit))

        draft = HabitDraft(habit: habit)
        draft.targetCount = 10
        #expect(draft.changesHistoricalRules(of: habit))

        draft = HabitDraft(habit: habit)
        draft.counterInterval = .weekly
        #expect(draft.changesHistoricalRules(of: habit))

        draft = HabitDraft(habit: habit)
        draft.kind = .habit
        #expect(draft.changesHistoricalRules(of: habit))
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
    func targetScaleUsesOrderedReadableValuesAndClampsItsPosition() {
        #expect(
            zip(HabitTargetScale.values, HabitTargetScale.values.dropFirst())
                .allSatisfy { pair in pair.0 < pair.1 }
        )
        #expect(HabitTargetScale.value(at: -10) == HabitTargetScale.minimumValue)
        #expect(HabitTargetScale.value(at: 10_000) == HabitTargetScale.maximumValue)
        #expect(
            HabitTargetScale.value(
                at: HabitTargetScale.position(for: 75)
            ) == 75
        )
        #expect(
            HabitTargetScale.value(
                at: HabitTargetScale.position(for: 37)
            ) == 40
        )
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
