import Foundation
import UserNotifications

struct HabitReminderSchedule {
    struct Entry: Equatable, Sendable {
        let identifier: String
        let weekday: Int
        let hour: Int
        let minute: Int
    }

    static func entries(
        habitID: UUID,
        scheduledWeekdays: [Int],
        hour: Int,
        minute: Int
    ) -> [Entry] {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else {
            return []
        }

        return Habit.normalizedWeekdays(scheduledWeekdays).map { mondayBasedWeekday in
            Entry(
                identifier: identifier(
                    habitID: habitID,
                    mondayBasedWeekday: mondayBasedWeekday
                ),
                weekday: ((mondayBasedWeekday + 1) % 7) + 1,
                hour: hour,
                minute: minute
            )
        }
    }

    static func identifiers(for habitID: UUID) -> [String] {
        (0..<7).map {
            identifier(habitID: habitID, mondayBasedWeekday: $0)
        }
    }

    private static func identifier(
        habitID: UUID,
        mondayBasedWeekday: Int
    ) -> String {
        "habit-reminder.\(habitID.uuidString).\(mondayBasedWeekday)"
    }
}

@MainActor
enum HabitReminderScheduler {
    static func requestAuthorizationIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .sound])
        @unknown default:
            return false
        }
    }

    static func synchronize(habit: Habit, locale: Locale) async throws {
        let center = UNUserNotificationCenter.current()
        let allIdentifiers = HabitReminderSchedule.identifiers(for: habit.identifier)
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        guard let reminder = habit.reminderComponents else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
        else {
            return
        }

        let entries = HabitReminderSchedule.entries(
            habitID: habit.identifier,
            scheduledWeekdays: habit.scheduledWeekdays,
            hour: reminder.hour ?? 0,
            minute: reminder.minute ?? 0
        )

        do {
            for entry in entries {
                let content = UNMutableNotificationContent()
                content.title = habit.name
                content.body = AppLocalization.string(
                    "Пора заняться привычкой.",
                    locale: locale
                )
                content.sound = .default
                content.userInfo = ["habitID": habit.identifier.uuidString]

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(
                        hour: entry.hour,
                        minute: entry.minute,
                        weekday: entry.weekday
                    ),
                    repeats: true
                )
                try await center.add(
                    UNNotificationRequest(
                        identifier: entry.identifier,
                        content: content,
                        trigger: trigger
                    )
                )
            }
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)
            throw error
        }
    }

    static func remove(habitID: UUID) {
        let identifiers = HabitReminderSchedule.identifiers(for: habitID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
