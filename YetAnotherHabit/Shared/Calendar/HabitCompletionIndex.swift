import Foundation

enum HabitCompletionIndex {
    static func counts(
        in completions: [HabitCompletion],
        for habitIdentifier: UUID? = nil
    ) -> [String: Int] {
        completions.reduce(into: [:]) { result, completion in
            guard completion.isCompleted, completion.count > 0 else { return }
            if let habitIdentifier,
               completion.habit?.identifier != habitIdentifier
            {
                return
            }

            result[completion.identifier] = max(
                result[completion.identifier, default: 0],
                completion.count
            )
        }
    }

    static func identifiers(
        in counts: [String: Int],
        habits: [Habit]
    ) -> Set<String> {
        habits.reduce(into: []) { result, habit in
            let prefix = "\(habit.identifier.uuidString)|"
            for (identifier, count) in counts
            where identifier.hasPrefix(prefix) && habit.isGoalMet(by: count) {
                result.insert(identifier)
            }
        }
    }
}
