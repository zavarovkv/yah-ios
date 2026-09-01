import Foundation
import SwiftData

extension AppSchemaV1 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var isCompleted: Bool = true
        var habit: AppSchemaV1.Habit?

        init(
            date: Date,
            dayKey: String,
            isCompleted: Bool = true,
            habit: AppSchemaV1.Habit
        ) {
            identifier = "\(habit.identifier.uuidString)|\(dayKey)"
            self.dayKey = dayKey
            self.date = date
            self.isCompleted = isCompleted
            self.habit = habit
        }
    }
}

extension AppSchemaV2 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var isCompleted: Bool = true
        var count: Int = 1
        var habit: AppSchemaV2.Habit?

        init(
            date: Date,
            dayKey: String,
            isCompleted: Bool = true,
            count: Int = 1,
            habit: AppSchemaV2.Habit
        ) {
            identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
            self.dayKey = dayKey
            self.date = date
            self.isCompleted = isCompleted
            self.count = max(1, count)
            self.habit = habit
        }

        static func identifier(habitID: UUID, dayKey: String) -> String {
            "\(habitID.uuidString)|\(dayKey)"
        }
    }
}

extension AppSchemaV3 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var isCompleted: Bool = true
        var count: Int = 1
        var habit: AppSchemaV3.Habit?

        init(
            date: Date,
            dayKey: String,
            isCompleted: Bool = true,
            count: Int = 1,
            habit: AppSchemaV3.Habit
        ) {
            identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
            self.dayKey = dayKey
            self.date = date
            self.isCompleted = isCompleted
            self.count = max(1, count)
            self.habit = habit
        }

        static func identifier(habitID: UUID, dayKey: String) -> String {
            "\(habitID.uuidString)|\(dayKey)"
        }
    }
}

extension AppSchemaV4 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var isCompleted: Bool = true
        var count: Int = 1
        var habit: AppSchemaV4.Habit?

        init(
            date: Date,
            dayKey: String,
            isCompleted: Bool = true,
            count: Int = 1,
            habit: AppSchemaV4.Habit
        ) {
            identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
            self.dayKey = dayKey
            self.date = date
            self.isCompleted = isCompleted
            self.count = max(1, count)
            self.habit = habit
        }

        static func identifier(habitID: UUID, dayKey: String) -> String {
            "\(habitID.uuidString)|\(dayKey)"
        }
    }
}

extension AppSchemaV5 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var isCompleted: Bool = true
        var count: Int = 1
        var habit: AppSchemaV5.Habit?

        init(
            date: Date,
            dayKey: String,
            isCompleted: Bool = true,
            count: Int = 1,
            habit: AppSchemaV5.Habit
        ) {
            identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
            self.dayKey = dayKey
            self.date = date
            self.isCompleted = isCompleted
            self.count = max(1, count)
            self.habit = habit
        }

        static func identifier(habitID: UUID, dayKey: String) -> String {
            "\(habitID.uuidString)|\(dayKey)"
        }
    }
}

extension AppSchemaV6 {
    @Model
    final class HabitCompletion {
        var identifier: String = ""
        var dayKey: String = ""
        var date: Date = Date.now
        var count: Int = 1
        var habit: AppSchemaV6.Habit?

        init(
            date: Date,
            dayKey: String,
            count: Int = 1,
            habit: AppSchemaV6.Habit
        ) {
            identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
            self.dayKey = dayKey
            self.date = date
            self.count = max(0, count)
            self.habit = habit
        }

        static func identifier(habitID: UUID, dayKey: String) -> String {
            "\(habitID.uuidString)|\(dayKey)"
        }
    }
}

typealias HabitCompletion = AppSchemaV6.HabitCompletion
