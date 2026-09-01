import Foundation
import Observation

struct HabitPresentationData {
    let habits: [Habit]
    let completionCounts: [String: Int]
    let completedIdentifiers: Set<String>
}

/// A short-lived UI cache that bridges the interval between a successful
/// SwiftData save and the corresponding `@Query` update.
@MainActor
@Observable
final class AppDataState {
    private var addedHabits: [UUID: Habit] = [:]
    private var deletedHabitIdentifiers: Set<UUID> = []
    private var completionCountOverrides: [String: Int] = [:]

    func recordAdded(_ habit: Habit) {
        addedHabits[habit.identifier] = habit
        deletedHabitIdentifiers.remove(habit.identifier)
    }

    func recordDeleted(identifier: UUID) {
        addedHabits.removeValue(forKey: identifier)
        deletedHabitIdentifiers.insert(identifier)
    }

    func recordCount(identifier: String, count: Int) {
        completionCountOverrides[identifier] = max(0, count)
    }

    func reconcile(habits: [Habit], completionCounts: [String: Int]) {
        let habitIdentifiers = Set(habits.map(\.identifier))
        addedHabits = addedHabits.filter { !habitIdentifiers.contains($0.key) }
        deletedHabitIdentifiers.formIntersection(habitIdentifiers)

        completionCountOverrides = completionCountOverrides.filter { identifier, value in
            completionCounts[identifier, default: 0] != value
        }
    }

    func visibleHabits(from persistedHabits: [Habit]) -> [Habit] {
        guard !addedHabits.isEmpty || !deletedHabitIdentifiers.isEmpty else {
            return persistedHabits
        }

        let persistedIdentifiers = Set(persistedHabits.map(\.identifier))
        let pending = addedHabits.values.filter {
            !persistedIdentifiers.contains($0.identifier)
        }

        return (persistedHabits + pending)
            .filter { !deletedHabitIdentifiers.contains($0.identifier) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func visibleCompletionCounts(
        from persistedCounts: [String: Int]
    ) -> [String: Int] {
        guard !completionCountOverrides.isEmpty else {
            return persistedCounts
        }

        return completionCountOverrides.reduce(into: persistedCounts) { result, override in
            if override.value > 0 {
                result[override.key] = override.value
            } else {
                result.removeValue(forKey: override.key)
            }
        }
    }

    func presentationData(
        persistedHabits: [Habit],
        persistedCompletionCounts: [String: Int]
    ) -> HabitPresentationData {
        let habits = visibleHabits(from: persistedHabits)
        let completionCounts = visibleCompletionCounts(
            from: persistedCompletionCounts
        )
        return HabitPresentationData(
            habits: habits,
            completionCounts: completionCounts,
            completedIdentifiers: HabitCompletionIndex.identifiers(
                in: completionCounts,
                habits: habits
            )
        )
    }
}
