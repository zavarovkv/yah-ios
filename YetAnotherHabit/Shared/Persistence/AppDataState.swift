import Foundation
import Observation

/// A short-lived UI cache that bridges the interval between a successful
/// SwiftData save and the corresponding `@Query` update.
@MainActor
@Observable
final class AppDataState {
    private var addedHabits: [UUID: Habit] = [:]
    private var deletedHabitIdentifiers: Set<UUID> = []
    private var completionOverrides: [String: Bool] = [:]

    func recordAdded(_ habit: Habit) {
        addedHabits[habit.identifier] = habit
        deletedHabitIdentifiers.remove(habit.identifier)
    }

    func recordDeleted(identifier: UUID) {
        addedHabits.removeValue(forKey: identifier)
        deletedHabitIdentifiers.insert(identifier)
    }

    func recordCompletion(identifier: String, isCompleted: Bool) {
        completionOverrides[identifier] = isCompleted
    }

    func reconcile(habits: [Habit], completionIdentifiers: Set<String>) {
        let habitIdentifiers = Set(habits.map(\.identifier))
        addedHabits = addedHabits.filter { !habitIdentifiers.contains($0.key) }
        deletedHabitIdentifiers.formIntersection(habitIdentifiers)

        completionOverrides = completionOverrides.filter { identifier, value in
            completionIdentifiers.contains(identifier) != value
        }
    }

    func visibleHabits(from persistedHabits: [Habit]) -> [Habit] {
        let persistedIdentifiers = Set(persistedHabits.map(\.identifier))
        let pending = addedHabits.values.filter {
            !persistedIdentifiers.contains($0.identifier)
        }

        return (persistedHabits + pending)
            .filter { !deletedHabitIdentifiers.contains($0.identifier) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func visibleCompletionIdentifiers(
        from persistedIdentifiers: Set<String>
    ) -> Set<String> {
        completionOverrides.reduce(into: persistedIdentifiers) { result, override in
            if override.value {
                result.insert(override.key)
            } else {
                result.remove(override.key)
            }
        }
    }
}
