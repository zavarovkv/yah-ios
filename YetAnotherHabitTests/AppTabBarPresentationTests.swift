import Testing
@testable import YetAnotherHabit

@MainActor
struct AppTabBarPresentationTests {
    @Test
    func indicatorUsesHysteresisAcrossTheNativeTransition() {
        let state = AppTabBarPresentationState()

        state.update(compactness: 0.63)
        #expect(state.indicatorMode == .count)

        state.update(compactness: 0.64)
        #expect(state.indicatorMode == .dot)

        state.update(compactness: 0.37)
        #expect(state.indicatorMode == .dot)

        state.update(compactness: 0.36)
        #expect(state.indicatorMode == .count)
    }

    @Test
    func titleVisibilityTracksBothDirectionsWithoutTiming() {
        var resolver = AppTabBarTitleVisibilityResolver()

        #expect(resolver.compactness(titleVisibility: 3) == 0)
        #expect(resolver.compactness(titleVisibility: 1.5) == 0.5)
        #expect(resolver.compactness(titleVisibility: 0) == 1)
        #expect(resolver.compactness(titleVisibility: 1.5) == 0.5)
        #expect(resolver.compactness(titleVisibility: 3) == 0)
    }

    @Test
    func upwardScrollTemporarilyForcesExpansion() {
        let state = AppTabBarPresentationState()
        var observationRequestCount = 0
        state.setObservationRequest {
            observationRequestCount += 1
        }

        state.reportScrollDirection(isScrollingDown: true)
        #expect(observationRequestCount == 1)
        #expect(state.forcesExpanded == false)

        state.reportScrollDirection(isScrollingDown: false)
        #expect(observationRequestCount == 2)
        #expect(state.forcesExpanded == true)

        state.reportScrollDirection(isScrollingDown: false)
        #expect(observationRequestCount == 2)
        #expect(state.forcesExpanded == true)

        state.update(compactness: 0.21)
        #expect(state.forcesExpanded == true)

        state.update(compactness: 0.20)
        #expect(state.forcesExpanded == false)

        state.finishScrollInteraction()
        state.reportScrollDirection(isScrollingDown: false)
        #expect(observationRequestCount == 3)
        #expect(state.forcesExpanded == true)

        state.finishScrollInteraction()
        #expect(state.forcesExpanded == false)
    }

    @Test
    func scrollDirectionUsesCumulativeTravelAndIgnoresJitter() {
        var resolver = HabitDayTabBarScrollDirectionResolver()

        #expect(
            resolver.direction(
                at: 90,
                isUserInteracting: false
            ) == nil
        )

        resolver.beginInteraction(at: 100)
        #expect(
            resolver.direction(
                at: 101,
                isUserInteracting: true
            ) == nil
        )
        #expect(
            resolver.direction(
                at: 103.9,
                isUserInteracting: true
            ) == nil
        )
        #expect(
            resolver.direction(
                at: 104,
                isUserInteracting: true
            ) == true
        )
        #expect(
            resolver.direction(
                at: 100.1,
                isUserInteracting: true
            ) == nil
        )
        #expect(
            resolver.direction(
                at: 80,
                isUserInteracting: true
            ) == false
        )

        resolver.endInteraction()
        resolver.beginInteraction(at: 100)
        #expect(
            resolver.direction(
                at: 104,
                isUserInteracting: true
            ) == true
        )

        resolver.endInteraction()
        resolver.beginInteraction(at: 100)
        #expect(
            resolver.direction(
                at: 76.1,
                isUserInteracting: true
            ) == nil
        )
        #expect(
            resolver.direction(
                at: 76,
                isUserInteracting: true
            ) == false
        )
    }

    @Test
    func endingInteractionPreparesTheNextDownwardGesture() {
        let state = AppTabBarPresentationState()
        var observationRequestCount = 0
        state.setObservationRequest {
            observationRequestCount += 1
        }

        state.reportScrollDirection(isScrollingDown: true)
        state.reportScrollDirection(isScrollingDown: true)
        #expect(observationRequestCount == 1)

        state.finishScrollInteraction()
        state.reportScrollDirection(isScrollingDown: true)
        #expect(observationRequestCount == 2)
    }
}
