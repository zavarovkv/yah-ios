import Foundation
import SwiftData

@MainActor
enum HabitCompletionStore {
    static let maximumCount = Int.max

    static func setCount(
        _ count: Int,
        habit: Habit,
        date: Date,
        calendar: Calendar,
        context: ModelContext
    ) throws {
        let normalizedCount = max(0, count)
        let periodStart = HabitCompletionPeriod.start(
            for: habit,
            containing: date,
            calendar: calendar
        )
        let periodKey = WeekCalendar.dayKey(for: periodStart, calendar: calendar)
        let identifier = HabitCompletion.identifier(
            habitID: habit.identifier,
            dayKey: periodKey
        )
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.identifier == identifier }
        )
        let storedCompletions = try context.fetch(descriptor)

        if normalizedCount > 0 {
            if storedCompletions.isEmpty {
                context.insert(
                    HabitCompletion(
                        date: periodStart,
                        dayKey: periodKey,
                        count: normalizedCount,
                        habit: habit
                    )
                )
            } else {
                // Cloud merges can temporarily produce duplicates. Keep one
                // canonical record and make every write idempotent.
                let canonicalCompletion = storedCompletions[0]
                canonicalCompletion.identifier = identifier
                canonicalCompletion.dayKey = periodKey
                canonicalCompletion.date = periodStart
                canonicalCompletion.count = normalizedCount
                canonicalCompletion.habit = habit
                storedCompletions.dropFirst().forEach(context.delete)
            }
        } else {
            storedCompletions.forEach(context.delete)
        }

        try context.save()
    }

    static func rebucketCompletions(
        for habit: Habit,
        calendar: Calendar,
        context: ModelContext
    ) throws {
        let habitIdentifier = habit.identifier
        let descriptor = FetchDescriptor<HabitCompletion>(
            predicate: #Predicate { $0.habit?.identifier == habitIdentifier }
        )
        let completions = try context.fetch(descriptor)
        reconcileBuckets(completions, calendar: calendar, context: context)
    }

    static func reconcileBuckets(
        _ completions: [HabitCompletion],
        calendar: Calendar,
        context: ModelContext
    ) {
        var recordsByDestination: [String: [HabitCompletion]] = [:]

        for completion in completions {
            guard completion.count > 0, let habit = completion.habit else {
                context.delete(completion)
                continue
            }

            let logicalDate = WeekCalendar.date(
                forDayKey: completion.dayKey,
                calendar: calendar
            ) ?? completion.date
            let identifier = HabitCompletionPeriod.identifier(
                for: habit,
                containing: logicalDate,
                calendar: calendar
            )
            recordsByDestination[identifier, default: []].append(completion)
        }

        for (identifier, records) in recordsByDestination {
            guard let canonical = records.first, let habit = canonical.habit else { continue }

            let recordsByOriginalDay = Dictionary(grouping: records) { completion in
                completion.dayKey.isEmpty
                    ? WeekCalendar.dayKey(for: completion.date, calendar: calendar)
                    : completion.dayKey
            }
            let count = recordsByOriginalDay.values.reduce(0) { partialResult, duplicates in
                saturatingSum(partialResult, duplicates.map(\.count).max() ?? 0)
            }
            let logicalDate = WeekCalendar.date(
                forDayKey: canonical.dayKey,
                calendar: calendar
            ) ?? canonical.date
            let periodStart = HabitCompletionPeriod.start(
                for: habit,
                containing: logicalDate,
                calendar: calendar
            )
            let periodKey = WeekCalendar.dayKey(for: periodStart, calendar: calendar)

            canonical.identifier = identifier
            canonical.dayKey = periodKey
            canonical.date = periodStart
            canonical.count = count
            records.dropFirst().forEach(context.delete)
        }
    }

    private static func saturatingSum(_ lhs: Int, _ rhs: Int) -> Int {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int.max : sum
    }
}
