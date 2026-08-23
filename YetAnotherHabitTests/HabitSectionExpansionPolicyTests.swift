import Testing
@testable import YetAnotherHabit

@MainActor
struct HabitSectionExpansionPolicyTests {
    @Test
    func pullTogglesCompletedFirstThenFallsBackToCounters() {
        #expect(
            HabitSectionExpansionPolicy.actionAfterPull(
                hasCompletedSection: false,
                isCompletedSectionExpanded: false,
                hasCountersSection: false,
                isCountersSectionExpanded: false
            ) == nil
        )
        #expect(
            HabitSectionExpansionPolicy.actionAfterPull(
                hasCompletedSection: true,
                isCompletedSectionExpanded: false,
                hasCountersSection: true,
                isCountersSectionExpanded: true
            ) == .init(section: .completed, isExpanded: true)
        )
        #expect(
            HabitSectionExpansionPolicy.actionAfterPull(
                hasCompletedSection: true,
                isCompletedSectionExpanded: true,
                hasCountersSection: true,
                isCountersSectionExpanded: false
            ) == .init(section: .completed, isExpanded: false)
        )
        #expect(
            HabitSectionExpansionPolicy.actionAfterPull(
                hasCompletedSection: false,
                isCompletedSectionExpanded: true,
                hasCountersSection: true,
                isCountersSectionExpanded: false
            ) == .init(section: .counters, isExpanded: true)
        )
    }
}
