import Observation
import SwiftUI

@MainActor
@Observable
final class HabitCompletionMoveState {
    private(set) var successPresentationTrigger = UUID()
    private var delayedSectionCounts: [UUID: Int] = [:]
    private var delayedSuccessCounts: [UUID: Int] = [:]
    private var tokens: [UUID: UUID] = [:]
    private var tasks: [UUID: Task<Void, Never>] = [:]

    var hasDelayedSuccessCounts: Bool {
        !delayedSuccessCounts.isEmpty
    }

    func sectionCount(for habitID: UUID, fallback: Int) -> Int {
        delayedSectionCounts[habitID] ?? fallback
    }

    func successCount(for habitID: UUID) -> Int? {
        delayedSuccessCounts[habitID]
    }

    func scheduleMove(
        for habitID: UUID,
        previousCount: Int,
        reduceMotion: Bool
    ) {
        tasks[habitID]?.cancel()

        let token = UUID()
        delayedSectionCounts[habitID] = previousCount
        delayedSuccessCounts[habitID] = previousCount
        tokens[habitID] = token

        let confirmationDelay = reduceMotion ? 0 : 400
        let moveAnimation: Animation? = reduceMotion
            ? nil
            : .snappy(duration: 0.32)
        let moveDuration = reduceMotion ? 0 : 320
        let successAnimation: Animation? = reduceMotion
            ? nil
            : .easeInOut(duration: 0.22)
        let successDuration = reduceMotion ? 0 : 220

        tasks[habitID] = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(confirmationDelay))
                guard let self, self.tokens[habitID] == token else { return }

                withAnimation(moveAnimation) {
                    self.delayedSectionCounts[habitID] = nil
                }

                try await Task.sleep(for: .milliseconds(moveDuration))
                guard self.tokens[habitID] == token else { return }

                withAnimation(successAnimation) {
                    self.delayedSuccessCounts[habitID] = nil
                    self.successPresentationTrigger = UUID()
                }

                try await Task.sleep(for: .milliseconds(successDuration))
                guard self.tokens[habitID] == token else { return }
                self.finishMove(for: habitID)
            } catch {
                // Cancellation is expected when the row disappears or a newer
                // completion supersedes the current transition.
            }
        }
    }

    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        tokens.removeAll()
        delayedSectionCounts.removeAll()
        delayedSuccessCounts.removeAll()
    }

    private func finishMove(for habitID: UUID) {
        tasks[habitID] = nil
        tokens[habitID] = nil
        delayedSectionCounts[habitID] = nil
        delayedSuccessCounts[habitID] = nil
    }
}
