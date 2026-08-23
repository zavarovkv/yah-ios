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

typealias HabitCompletion = AppSchemaV3.HabitCompletion
