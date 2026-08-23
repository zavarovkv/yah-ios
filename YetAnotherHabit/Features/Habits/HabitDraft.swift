import Foundation

struct HabitDraft: Equatable {
    var kind: HabitKind
    var name: String
    var icon: String
    var color: HabitColor
    var scheduledWeekdays: Set<Int>
    var targetCount: Int?

    init(
        kind: HabitKind = .habit,
        name: String = "",
        icon: String = "checkmark",
        color: HabitColor = .blue,
        scheduledWeekdays: Set<Int> = Set(0..<7),
        targetCount: Int? = nil
    ) {
        self.kind = kind
        self.name = name
        self.icon = icon
        self.color = color
        self.scheduledWeekdays = Set(Habit.normalizedWeekdays(scheduledWeekdays))
        self.targetCount = Habit.normalizedTargetCount(targetCount, kind: kind)
    }

    init(habit: Habit) {
        self.init(
            kind: habit.kind,
            name: habit.name,
            icon: habit.icon,
            color: HabitColor(rawValue: habit.color) ?? .blue,
            scheduledWeekdays: Set(habit.scheduledWeekdays),
            targetCount: habit.effectiveTargetCount
        )
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !normalizedName.isEmpty && !scheduledWeekdays.isEmpty
    }

    func makeHabit(createdAt: Date) -> Habit {
        Habit(
            name: normalizedName,
            icon: icon,
            color: color.rawValue,
            scheduledWeekdays: scheduledWeekdays.sorted(),
            createdAt: createdAt,
            kind: kind,
            targetCount: normalizedTargetCount
        )
    }

    func apply(to habit: Habit) {
        habit.name = normalizedName
        habit.icon = icon
        habit.color = color.rawValue
        habit.scheduledWeekdays = Habit.normalizedWeekdays(scheduledWeekdays)
        habit.kind = kind
        habit.targetCount = normalizedTargetCount
    }

    var normalizedTargetCount: Int? {
        Habit.normalizedTargetCount(targetCount, kind: kind)
    }

    static func randomized() -> HabitDraft {
        HabitDraft(
            icon: HabitAppearanceOptions.randomIcon(),
            color: HabitAppearanceOptions.randomColor()
        )
    }
}
