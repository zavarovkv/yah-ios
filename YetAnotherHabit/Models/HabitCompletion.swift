import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var identifier: String = ""
    var dayKey: String = ""
    var date: Date = Date.now
    var isCompleted: Bool = true
    var habit: Habit?

    init(
        date: Date,
        dayKey: String,
        isCompleted: Bool = true,
        habit: Habit
    ) {
        self.identifier = Self.identifier(habitID: habit.identifier, dayKey: dayKey)
        self.dayKey = dayKey
        self.date = date
        self.isCompleted = isCompleted
        self.habit = habit
    }

    static func identifier(habitID: UUID, dayKey: String) -> String {
        "\(habitID.uuidString)|\(dayKey)"
    }
}
