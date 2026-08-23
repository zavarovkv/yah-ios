import Foundation
import SwiftData

enum HabitKind: String, CaseIterable, Identifiable {
    case habit
    case counter

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

typealias Habit = AppSchemaV3.Habit
