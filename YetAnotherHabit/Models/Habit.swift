import Foundation
import SwiftData

enum HabitKind: String, CaseIterable, Identifiable {
    case habit
    case counter

    var id: Self { self }
}

enum CounterInterval: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly

    var id: Self { self }
}

extension AppSchemaV1 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV1.HabitCompletion.habit)
        var completions: [AppSchemaV1.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = scheduledWeekdays
            self.createdAt = createdAt
        }
    }
}

extension AppSchemaV2 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)
        var kindRawValue: String = HabitKind.habit.rawValue

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV2.HabitCompletion.habit)
        var completions: [AppSchemaV2.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now,
            kind: HabitKind = .habit
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = Self.normalizedWeekdays(scheduledWeekdays)
            self.createdAt = createdAt
            kindRawValue = kind.rawValue
        }

        var kind: HabitKind {
            get { HabitKind(rawValue: kindRawValue) ?? .habit }
            set { kindRawValue = newValue.rawValue }
        }

        func isScheduled(on date: Date, calendar: Calendar) -> Bool {
            calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
                && scheduledWeekdays.contains(
                    WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
                )
        }

        static func normalizedWeekdays<S: Sequence>(_ weekdays: S) -> [Int]
        where S.Element == Int {
            Array(Set(weekdays.filter { (0..<7).contains($0) })).sorted()
        }
    }
}

extension AppSchemaV3 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)
        var kindRawValue: String = HabitKind.habit.rawValue
        var targetCount: Int?

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV3.HabitCompletion.habit)
        var completions: [AppSchemaV3.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now,
            kind: HabitKind = .habit,
            targetCount: Int? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = Self.normalizedWeekdays(scheduledWeekdays)
            self.createdAt = createdAt
            kindRawValue = kind.rawValue
            self.targetCount = Self.normalizedTargetCount(targetCount, kind: kind)
        }

        var kind: HabitKind {
            get { HabitKind(rawValue: kindRawValue) ?? .habit }
            set {
                kindRawValue = newValue.rawValue
                targetCount = Self.normalizedTargetCount(targetCount, kind: newValue)
            }
        }

        var effectiveTargetCount: Int? {
            Self.normalizedTargetCount(targetCount, kind: kind)
        }

        var contributesToDailyGoal: Bool {
            kind == .habit || effectiveTargetCount != nil
        }

        func isGoalMet(by count: Int) -> Bool {
            guard count > 0 else { return false }
            guard let effectiveTargetCount else { return true }
            return count >= effectiveTargetCount
        }

        func isScheduled(on date: Date, calendar: Calendar) -> Bool {
            calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
                && scheduledWeekdays.contains(
                    WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
                )
        }

        static func normalizedWeekdays<S: Sequence>(_ weekdays: S) -> [Int]
        where S.Element == Int {
            Array(Set(weekdays.filter { (0..<7).contains($0) })).sorted()
        }

        static func normalizedTargetCount(_ targetCount: Int?, kind: HabitKind) -> Int? {
            guard kind == .counter, let targetCount, targetCount > 0 else {
                return nil
            }
            return targetCount
        }
    }
}

extension AppSchemaV4 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)
        var kindRawValue: String = HabitKind.habit.rawValue
        var targetCount: Int?
        var counterIntervalRawValue: String = CounterInterval.daily.rawValue

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV4.HabitCompletion.habit)
        var completions: [AppSchemaV4.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now,
            kind: HabitKind = .habit,
            targetCount: Int? = nil,
            counterInterval: CounterInterval = .daily
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = Self.normalizedWeekdays(scheduledWeekdays)
            self.createdAt = createdAt
            kindRawValue = kind.rawValue
            self.targetCount = Self.normalizedTargetCount(targetCount, kind: kind)
            counterIntervalRawValue = counterInterval.rawValue
        }

        var kind: HabitKind {
            get { HabitKind(rawValue: kindRawValue) ?? .habit }
            set {
                kindRawValue = newValue.rawValue
                targetCount = Self.normalizedTargetCount(targetCount, kind: newValue)
            }
        }

        var counterInterval: CounterInterval {
            get { CounterInterval(rawValue: counterIntervalRawValue) ?? .daily }
            set { counterIntervalRawValue = newValue.rawValue }
        }

        var effectiveCounterInterval: CounterInterval {
            kind == .counter ? counterInterval : .daily
        }

        var effectiveTargetCount: Int? {
            Self.normalizedTargetCount(targetCount, kind: kind)
        }

        var contributesToDailyGoal: Bool {
            kind == .habit || effectiveTargetCount != nil
        }

        func isGoalMet(by count: Int) -> Bool {
            guard count > 0 else { return false }
            guard let effectiveTargetCount else { return true }
            return count >= effectiveTargetCount
        }

        func isScheduled(on date: Date, calendar: Calendar) -> Bool {
            calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
                && scheduledWeekdays.contains(
                    WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
                )
        }

        static func normalizedWeekdays<S: Sequence>(_ weekdays: S) -> [Int]
        where S.Element == Int {
            Array(Set(weekdays.filter { (0..<7).contains($0) })).sorted()
        }

        static func normalizedTargetCount(_ targetCount: Int?, kind: HabitKind) -> Int? {
            guard kind == .counter, let targetCount, targetCount > 0 else {
                return nil
            }
            return targetCount
        }
    }
}

extension AppSchemaV5 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)
        var kindRawValue: String = HabitKind.habit.rawValue
        var targetCount: Int?
        var counterIntervalRawValue: String = CounterInterval.daily.rawValue
        var reminderHour: Int?
        var reminderMinute: Int?

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV5.HabitCompletion.habit)
        var completions: [AppSchemaV5.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now,
            kind: HabitKind = .habit,
            targetCount: Int? = nil,
            counterInterval: CounterInterval = .daily,
            reminderHour: Int? = nil,
            reminderMinute: Int? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = Self.normalizedWeekdays(scheduledWeekdays)
            self.createdAt = createdAt
            kindRawValue = kind.rawValue
            self.targetCount = Self.normalizedTargetCount(targetCount, kind: kind)
            counterIntervalRawValue = counterInterval.rawValue
            setReminder(hour: reminderHour, minute: reminderMinute)
        }

        var kind: HabitKind {
            get { HabitKind(rawValue: kindRawValue) ?? .habit }
            set {
                kindRawValue = newValue.rawValue
                targetCount = Self.normalizedTargetCount(targetCount, kind: newValue)
            }
        }

        var counterInterval: CounterInterval {
            get { CounterInterval(rawValue: counterIntervalRawValue) ?? .daily }
            set { counterIntervalRawValue = newValue.rawValue }
        }

        var effectiveCounterInterval: CounterInterval {
            kind == .counter ? counterInterval : .daily
        }

        var effectiveTargetCount: Int? {
            Self.normalizedTargetCount(targetCount, kind: kind)
        }

        var reminderComponents: DateComponents? {
            guard let reminderHour, let reminderMinute,
                  (0..<24).contains(reminderHour),
                  (0..<60).contains(reminderMinute)
            else {
                return nil
            }
            return DateComponents(hour: reminderHour, minute: reminderMinute)
        }

        var contributesToDailyGoal: Bool {
            kind == .habit || effectiveTargetCount != nil
        }

        func setReminder(hour: Int?, minute: Int?) {
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

        func isGoalMet(by count: Int) -> Bool {
            guard count > 0 else { return false }
            guard let effectiveTargetCount else { return true }
            return count >= effectiveTargetCount
        }

        func isScheduled(on date: Date, calendar: Calendar) -> Bool {
            calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
                && scheduledWeekdays.contains(
                    WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
                )
        }

        static func normalizedWeekdays<S: Sequence>(_ weekdays: S) -> [Int]
        where S.Element == Int {
            Array(Set(weekdays.filter { (0..<7).contains($0) })).sorted()
        }

        static func normalizedTargetCount(_ targetCount: Int?, kind: HabitKind) -> Int? {
            guard kind == .counter, let targetCount, targetCount > 0 else {
                return nil
            }
            return targetCount
        }
    }
}

extension AppSchemaV6 {
    @Model
    final class Habit {
        var identifier: UUID = UUID()
        var name: String = ""
        var icon: String = "checkmark"
        var color: String = "blue"
        var createdAt: Date = Date.now
        var scheduledWeekdays: [Int] = Array(0..<7)
        var kindRawValue: String = HabitKind.habit.rawValue
        var targetCount: Int?
        var counterIntervalRawValue: String = CounterInterval.daily.rawValue
        var reminderHour: Int?
        var reminderMinute: Int?

        @Relationship(deleteRule: .cascade, inverse: \AppSchemaV6.HabitCompletion.habit)
        var completions: [AppSchemaV6.HabitCompletion] = []

        init(
            identifier: UUID = UUID(),
            name: String,
            icon: String,
            color: String,
            scheduledWeekdays: [Int] = Array(0..<7),
            createdAt: Date = .now,
            kind: HabitKind = .habit,
            targetCount: Int? = nil,
            counterInterval: CounterInterval = .daily,
            reminderHour: Int? = nil,
            reminderMinute: Int? = nil
        ) {
            self.identifier = identifier
            self.name = name
            self.icon = icon
            self.color = color
            self.scheduledWeekdays = Self.normalizedWeekdays(scheduledWeekdays)
            self.createdAt = createdAt
            kindRawValue = kind.rawValue
            self.targetCount = Self.normalizedTargetCount(targetCount, kind: kind)
            counterIntervalRawValue = counterInterval.rawValue
            setReminder(hour: reminderHour, minute: reminderMinute)
        }

        var kind: HabitKind {
            get { HabitKind(rawValue: kindRawValue) ?? .habit }
            set {
                kindRawValue = newValue.rawValue
                targetCount = Self.normalizedTargetCount(targetCount, kind: newValue)
            }
        }

        var counterInterval: CounterInterval {
            get { CounterInterval(rawValue: counterIntervalRawValue) ?? .daily }
            set { counterIntervalRawValue = newValue.rawValue }
        }

        var effectiveCounterInterval: CounterInterval {
            kind == .counter ? counterInterval : .daily
        }

        var effectiveTargetCount: Int? {
            Self.normalizedTargetCount(targetCount, kind: kind)
        }

        var reminderComponents: DateComponents? {
            guard let reminderHour, let reminderMinute,
                  (0..<24).contains(reminderHour),
                  (0..<60).contains(reminderMinute)
            else {
                return nil
            }
            return DateComponents(hour: reminderHour, minute: reminderMinute)
        }

        var contributesToDailyGoal: Bool {
            kind == .habit || effectiveTargetCount != nil
        }

        func setReminder(hour: Int?, minute: Int?) {
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

        func isGoalMet(by count: Int) -> Bool {
            guard count > 0 else { return false }
            guard let effectiveTargetCount else { return true }
            return count >= effectiveTargetCount
        }

        func isScheduled(on date: Date, calendar: Calendar) -> Bool {
            calendar.startOfDay(for: date) >= calendar.startOfDay(for: createdAt)
                && scheduledWeekdays.contains(
                    WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
                )
        }

        static func normalizedWeekdays<S: Sequence>(_ weekdays: S) -> [Int]
        where S.Element == Int {
            Array(Set(weekdays.filter { (0..<7).contains($0) })).sorted()
        }

        static func normalizedTargetCount(_ targetCount: Int?, kind: HabitKind) -> Int? {
            guard kind == .counter, let targetCount, targetCount > 0 else {
                return nil
            }
            return targetCount
        }
    }
}

typealias Habit = AppSchemaV6.Habit
