import Foundation

enum HabitCompletionIndex {
    static func counts(
        in completions: [HabitCompletion],
        for habitIdentifier: UUID? = nil
    ) -> [String: Int] {
        completions.reduce(into: [:]) { result, completion in
            guard completion.count > 0 else { return }
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
        let habitsByIdentifier = habits.reduce(into: [String: Habit]()) { result, habit in
            result[habit.identifier.uuidString] = habit
        }

        return counts.reduce(into: []) { result, entry in
            guard
                let separatorIndex = entry.key.firstIndex(of: "|"),
                let habit = habitsByIdentifier[String(entry.key[..<separatorIndex])],
                habit.isGoalMet(by: entry.value)
            else {
                return
            }

            result.insert(entry.key)
        }
    }

    static func totalCount(in counts: [String: Int]) -> Int {
        counts.values.reduce(0) { result, count in
            let (sum, overflow) = result.addingReportingOverflow(max(0, count))
            return overflow ? Int.max : sum
        }
    }
}
