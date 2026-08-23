enum HabitSectionExpansionPolicy {
    enum Section: Equatable {
        case completed
        case counters
    }

    struct Action: Equatable {
        let section: Section
        let isExpanded: Bool
    }

    static func actionAfterPull(
        hasCompletedSection: Bool,
        isCompletedSectionExpanded: Bool,
        hasCountersSection: Bool,
        isCountersSectionExpanded: Bool
    ) -> Action? {
        if hasCompletedSection {
            return Action(
                section: .completed,
                isExpanded: !isCompletedSectionExpanded
            )
        }
        if hasCountersSection {
            return Action(
                section: .counters,
                isExpanded: !isCountersSectionExpanded
            )
        }
        return nil
    }
}
