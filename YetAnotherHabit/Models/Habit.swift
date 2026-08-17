import Foundation
import SwiftData

@Model
final class Habit {
    var identifier: UUID = UUID()
    var name: String = ""
    var icon: String = "checkmark"
    var color: String = "blue"
    var createdAt: Date = Date.now
    var scheduledWeekdays: [Int] = Array(0..<7)

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

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

    func isScheduled(on date: Date, calendar: Calendar) -> Bool {
        calendar.startOfDay(for: createdAt) <= calendar.startOfDay(for: date)
            && scheduledWeekdays.contains(
                WeekCalendar.mondayBasedWeekday(for: date, calendar: calendar)
            )
    }
}
