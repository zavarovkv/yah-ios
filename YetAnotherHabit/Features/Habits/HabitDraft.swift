import Foundation

struct HabitDraft: Equatable {
    var kind: HabitKind
    var name: String
    var icon: String
    var color: HabitColor
    var scheduledWeekdays: Set<Int>
    var targetCount: Int?
    var counterInterval: CounterInterval
    var reminderHour: Int?
    var reminderMinute: Int?

    init(
        kind: HabitKind = .habit,
        name: String = "",
        icon: String = "checkmark",
        color: HabitColor = .blue,
        scheduledWeekdays: Set<Int> = Set(0..<7),
        targetCount: Int? = nil,
        counterInterval: CounterInterval = .daily,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.kind = kind
        self.name = name
        self.icon = icon
        self.color = color
        self.scheduledWeekdays = Set(Habit.normalizedWeekdays(scheduledWeekdays))
        self.targetCount = Habit.normalizedTargetCount(targetCount, kind: kind)
        self.counterInterval = counterInterval
        self.reminderHour = nil
        self.reminderMinute = nil
        setReminder(hour: reminderHour, minute: reminderMinute)
    }

    init(habit: Habit) {
        self.init(
            kind: habit.kind,
            name: habit.name,
            icon: habit.icon,
            color: HabitColor(rawValue: habit.color) ?? .blue,
            scheduledWeekdays: Set(habit.scheduledWeekdays),
            targetCount: habit.effectiveTargetCount,
            counterInterval: habit.effectiveCounterInterval,
            reminderHour: habit.reminderHour,
            reminderMinute: habit.reminderMinute
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
            targetCount: normalizedTargetCount,
            counterInterval: normalizedCounterInterval,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
    }

    func apply(to habit: Habit) {
        habit.name = normalizedName
        habit.icon = icon
        habit.color = color.rawValue
        habit.scheduledWeekdays = Habit.normalizedWeekdays(scheduledWeekdays)
        habit.kind = kind
        habit.counterInterval = normalizedCounterInterval
        habit.targetCount = normalizedTargetCount
        habit.setReminder(hour: reminderHour, minute: reminderMinute)
    }

    var normalizedTargetCount: Int? {
        Habit.normalizedTargetCount(targetCount, kind: kind)
    }

    var normalizedCounterInterval: CounterInterval {
        kind == .counter ? counterInterval : .daily
    }

    var hasReminder: Bool {
        reminderHour != nil && reminderMinute != nil
    }

    mutating func setReminder(hour: Int?, minute: Int?) {
        guard let hour, let minute,
              (0..<24).contains(hour),
              (0..<60).contains(minute)
        else {
            reminderHour = nil
            reminderMinute = nil
            return
        }
        reminderHour = hour
        reminderMinute = minute
    }

    func changesReminder(of habit: Habit) -> Bool {
        reminderHour != habit.reminderHour || reminderMinute != habit.reminderMinute
    }

    func changesHistoricalRules(of habit: Habit) -> Bool {
        kind != habit.kind
            || Habit.normalizedWeekdays(scheduledWeekdays) != habit.scheduledWeekdays
            || normalizedTargetCount != habit.effectiveTargetCount
            || normalizedCounterInterval != habit.effectiveCounterInterval
    }

    static func randomized() -> HabitDraft {
        HabitDraft(
            icon: HabitAppearanceOptions.randomIcon(),
            color: HabitAppearanceOptions.randomColor()
        )
    }
}
