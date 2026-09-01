import Observation
import SwiftData
import SwiftUI

private struct HabitDayScrollMetrics: Equatable {
    let isAtTop: Bool
    let pullDistance: CGFloat
    let scrollOffset: CGFloat
}

struct HabitDayTabBarScrollDirectionResolver {
    // A little more cumulative travel is required before an upward gesture
    // requests expansion, avoiding a mode change from incidental finger jitter.
    private static let downwardDirectionalTravel: CGFloat = 4
    private static let upwardDirectionalTravel: CGFloat = 24
    private var referenceOffset: CGFloat?
    private var lastDirectionWasDown: Bool?

    mutating func beginInteraction(at offset: CGFloat) {
        referenceOffset = offset
        lastDirectionWasDown = nil
    }

    mutating func direction(
        at offset: CGFloat,
        isUserInteracting: Bool
    ) -> Bool? {
        guard isUserInteracting else { return nil }
        guard let referenceOffset else {
            self.referenceOffset = offset
            return nil
        }

        switch lastDirectionWasDown {
        case nil:
            let travel = offset - referenceOffset
            if travel >= Self.downwardDirectionalTravel {
                lastDirectionWasDown = true
                self.referenceOffset = offset
                return true
            }
            if travel <= -Self.upwardDirectionalTravel {
                lastDirectionWasDown = false
                self.referenceOffset = offset
                return false
            }
        case true:
            if offset > referenceOffset {
                self.referenceOffset = offset
            } else if referenceOffset - offset >= Self.upwardDirectionalTravel {
                lastDirectionWasDown = false
                self.referenceOffset = offset
                return false
            }
        case false:
            if offset < referenceOffset {
                self.referenceOffset = offset
            } else if offset - referenceOffset >= Self.downwardDirectionalTravel {
                lastDirectionWasDown = true
                self.referenceOffset = offset
                return true
            }
        }

        return nil
    }

    mutating func endInteraction() {
        referenceOffset = nil
        lastDirectionWasDown = nil
    }
}

@MainActor
@Observable
private final class HabitDayScrollInteractionState {
    var isInteracting = false
    var didPullDuringInteraction = false
    var isAwaitingRebound = false
    var latestPullDistance: CGFloat = 0
    var latestScrollOffset: CGFloat = 0
    @ObservationIgnored var tabBarDirectionResolver =
        HabitDayTabBarScrollDirectionResolver()
}

private enum HabitDayListSection: Hashable {
    case pending
    case counters
    case completed
}

private enum HabitDayListItem: Identifiable {
    enum ID: Hashable {
        case dailySuccess
        case header(HabitDayListSection)
        case habit(UUID, HabitDayListSection)
    }

    case dailySuccess
    case header(HabitDayListSection, count: Int)
    case habit(Habit, section: HabitDayListSection)

    var id: ID {
        switch self {
        case .dailySuccess:
            return .dailySuccess
        case .header(let section, _):
            return .header(section)
        case .habit(let habit, let section):
            return .habit(habit.identifier, section)
        }
    }
}

struct HabitDayListView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext

    let habits: [Habit]
    let selectedDate: Date
    let completionCounts: [String: Int]
    let completedIdentifiers: Set<String>
    let onCountChanged: (_ identifier: String, _ count: Int) -> Void
    let onOpenHabit: (UUID) -> Void
    let onEditHabit: (UUID) -> Void
    let onScrollTopChanged: (Bool) -> Void
    let onScrollOffsetChanged: (CGFloat) -> Void
    let onTabBarScrollDirectionChanged: (Bool) -> Void
    let onTabBarScrollInteractionEnded: () -> Void
    let onPullChanged: (CGFloat) -> Void
    let onPullEnded: () -> Void
    let onPullRebounded: () -> Void
    let topInset: CGFloat
    let pullReboundCompletionDistance: CGFloat
    let showsScrollIndicator: Bool
    @Binding var prefersCompletedSectionExpanded: Bool
    @Binding var prefersCountersSectionExpanded: Bool
    @Binding var persistenceError: String?
    @State private var completionMoveState = HabitCompletionMoveState()
    @State private var scrollInteractionState = HabitDayScrollInteractionState()

    var body: some View {
        let sections = HabitDaySorter.sections(
            in: habits,
            for: selectedDate,
            calendar: calendar
        ) { sectionCount(for: $0) }
        let listItems = listItems(for: sections)

        List {
            Color.clear
                .frame(height: topInset)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .accessibilityHidden(true)

            ForEach(listItems) { item in
                listRow(for: item)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(
            showsScrollIndicator ? .automatic : .hidden,
            axes: .vertical
        )
        .scrollClipDisabled()
        .contentMargins(.top, 0, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.snappy(duration: 0.3), value: habits.map(\.identifier))
        .onScrollGeometryChange(for: HabitDayScrollMetrics.self) { geometry in
            let verticalOffset = geometry.contentOffset.y + geometry.contentInsets.top
            return HabitDayScrollMetrics(
                isAtTop: verticalOffset <= 1,
                pullDistance: max(-verticalOffset, 0),
                scrollOffset: max(verticalOffset, 0)
            )
        } action: { oldMetrics, metrics in
            scrollInteractionState.latestPullDistance = metrics.pullDistance
            scrollInteractionState.latestScrollOffset = metrics.scrollOffset
            reportTabBarScrollDirection(offset: metrics.scrollOffset)
            if oldMetrics.isAtTop != metrics.isAtTop {
                onScrollTopChanged(metrics.isAtTop)
            }
            onScrollOffsetChanged(metrics.scrollOffset)
            if scrollInteractionState.isInteracting,
               (metrics.pullDistance > 0 || oldMetrics.pullDistance > 0) {
                scrollInteractionState.didPullDuringInteraction = true
                onPullChanged(metrics.pullDistance)
            }
            if scrollInteractionState.isAwaitingRebound,
               metrics.pullDistance <= pullReboundCompletionDistance {
                finishPullRebound()
            }
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            let wasInteracting = oldPhase == .interacting
            scrollInteractionState.isInteracting = newPhase == .interacting
            if newPhase == .interacting {
                scrollInteractionState.isAwaitingRebound = false
                scrollInteractionState.tabBarDirectionResolver.beginInteraction(
                    at: scrollInteractionState.latestScrollOffset
                )
            }
            if wasInteracting, newPhase != .interacting {
                scrollInteractionState.tabBarDirectionResolver.endInteraction()
                onTabBarScrollInteractionEnded()
            }
            if wasInteracting,
               newPhase != .interacting,
               scrollInteractionState.didPullDuringInteraction {
                scrollInteractionState.didPullDuringInteraction = false
                scrollInteractionState.isAwaitingRebound = true
                onPullEnded()
                if scrollInteractionState.latestPullDistance <= pullReboundCompletionDistance {
                    finishPullRebound()
                }
            }
            if newPhase == .idle {
                finishPullRebound()
            }
        }
        .onDisappear {
            completionMoveState.cancelAll()
            scrollInteractionState.tabBarDirectionResolver.endInteraction()
            onTabBarScrollInteractionEnded()
        }
        .sensoryFeedback(
            .success,
            trigger: completionMoveState.successPresentationTrigger
        ) { _, _ in
            dailySuccessSnapshot.isComplete
        }
    }

    private func reportTabBarScrollDirection(offset: CGFloat) {
        guard let isScrollingDown =
                scrollInteractionState.tabBarDirectionResolver.direction(
                    at: offset,
                    isUserInteracting: scrollInteractionState.isInteracting
                ) else {
            return
        }

        onTabBarScrollDirectionChanged(isScrollingDown)
    }

    private func listItems(
        for sections: HabitDaySorter.Sections
    ) -> [HabitDayListItem] {
        var items: [HabitDayListItem] = []

        if showsDailySuccessBanner {
            items.append(.dailySuccess)
        }

        if !sections.pending.isEmpty {
            items.append(.header(.pending, count: sections.pending.count))
            items.append(contentsOf: sections.pending.map {
                .habit($0, section: .pending)
            })
        }

        if !sections.openCounters.isEmpty {
            items.append(.header(.counters, count: sections.openCounters.count))
            if isSectionExpanded(.counters) {
                items.append(contentsOf: sections.openCounters.map {
                    .habit($0, section: .counters)
                })
            }
        }

        if !sections.completed.isEmpty {
            items.append(.header(.completed, count: sections.completed.count))
            if isSectionExpanded(.completed) {
                items.append(contentsOf: sections.completed.map {
                    .habit($0, section: .completed)
                })
            }
        }

        return items
    }

    @ViewBuilder
    private func listRow(for item: HabitDayListItem) -> some View {
        switch item {
        case .dailySuccess:
            dailySuccessBanner
        case .header(let section, let count):
            sectionHeaderRow(for: section, count: count)
        case .habit(let habit, _):
            habitRow(for: habit)
        }
    }

    private var dailySuccessBanner: some View {
        DailySuccessBannerView(snapshot: dailySuccessSnapshot)
            .transition(dailySuccessTransition)
    }

    private var showsDailySuccessBanner: Bool {
        dailySuccessSnapshot.isComplete
    }

    private var dailySuccessSnapshot: HabitDailySuccessPolicy.Snapshot {
        HabitDailySuccessPolicy.snapshot(
            for: selectedDate,
            habits: habits,
            completionCounts: presentationCompletionCounts,
            calendar: calendar
        )
    }

    private var dailySuccessTransition: AnyTransition {
        accessibilityReduceMotion
            ? .opacity
            : .opacity
                .combined(with: .move(edge: .top))
                .combined(with: .scale(scale: 0.96))
    }

    private var presentationCompletionCounts: [String: Int] {
        guard completionMoveState.hasDelayedSuccessCounts else {
            return completionCounts
        }

        var counts = completionCounts
        for habit in habits {
            guard let delayedCount = completionMoveState.successCount(
                for: habit.identifier
            ) else {
                continue
            }
            counts[completionIdentifier(for: habit)] = delayedCount
        }
        return counts
    }

    private func habitRow(for habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            count: count(for: habit),
            streak: streak(for: habit),
            canChangeCompletion: canChangeCompletion,
            onToggleCompletion: { toggleCompletion(for: habit) },
            onCountChanged: { setCount($0, for: habit) },
            onOpenAnalytics: { onOpenHabit(habit.identifier) }
        )
        .transition(habitSectionTransition)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onEditHabit(habit.identifier)
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canChangeCompletion, habit.kind == .habit {
                Button {
                    toggleCompletion(for: habit)
                } label: {
                    if isCompleted(habit) {
                        Label("Не выполнено", systemImage: "xmark")
                    } else {
                        Label("Выполнено", systemImage: "checkmark")
                    }
                }
                .tint(isCompleted(habit) ? .gray : .green)
            }
        }
    }

    private func isSectionExpanded(_ section: HabitDayListSection) -> Bool {
        if isHistoricalDay {
            return true
        }

        switch section {
        case .pending:
            return true
        case .counters:
            return prefersCountersSectionExpanded
        case .completed:
            return prefersCompletedSectionExpanded
        }
    }

    @ViewBuilder
    private func sectionHeaderRow(
        for section: HabitDayListSection,
        count: Int
    ) -> some View {
        switch section {
        case .pending:
            HabitSectionHeaderView(
                title: "Не выполнено",
                count: count,
                isExpanded: true,
                showsDisclosureIndicator: false
            )
            .habitSectionHeaderRowStyle()
        case .counters:
            collapsibleSectionHeaderRow(
                title: "Счётчики",
                count: count,
                expandedPreference: $prefersCountersSectionExpanded,
                expandedHint: "Скрыть счётчики",
                collapsedHint: "Показать счётчики"
            )
        case .completed:
            collapsibleSectionHeaderRow(
                title: "Выполнено",
                count: count,
                expandedPreference: $prefersCompletedSectionExpanded,
                expandedHint: "Скрыть выполненные привычки",
                collapsedHint: "Показать выполненные привычки"
            )
        }
    }

    @ViewBuilder
    private func collapsibleSectionHeaderRow(
        title: LocalizedStringKey,
        count: Int,
        expandedPreference: Binding<Bool>,
        expandedHint: LocalizedStringKey,
        collapsedHint: LocalizedStringKey
    ) -> some View {
        if isHistoricalDay {
            HabitSectionHeaderView(
                title: title,
                count: count,
                isExpanded: true,
                showsDisclosureIndicator: false
            )
            .habitSectionHeaderRowStyle()
        } else {
            Button {
                withAnimation(accordionAnimation) {
                    expandedPreference.wrappedValue.toggle()
                }
            } label: {
                HabitSectionHeaderView(
                    title: title,
                    count: count,
                    isExpanded: expandedPreference.wrappedValue,
                    showsDisclosureIndicator: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                expandedPreference.wrappedValue ? expandedHint : collapsedHint
            )
            .habitSectionHeaderRowStyle()
        }
    }

    private var accordionAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .smooth(duration: 0.28)
    }

    private var habitSectionTransition: AnyTransition {
        accessibilityReduceMotion
            ? .identity
            : .asymmetric(
                insertion: .opacity,
                removal: .identity
            )
    }

    private func finishPullRebound() {
        guard scrollInteractionState.isAwaitingRebound else { return }

        scrollInteractionState.isAwaitingRebound = false
        onPullRebounded()
    }

    private var isHistoricalDay: Bool {
        HabitDayPolicy.isHistorical(selectedDate, calendar: calendar)
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        habit.isGoalMet(by: count(for: habit))
    }

    private func count(for habit: Habit) -> Int {
        completionCounts[completionIdentifier(for: habit), default: 0]
    }

    private func sectionCount(for habit: Habit) -> Int {
        completionMoveState.sectionCount(
            for: habit.identifier,
            fallback: count(for: habit)
        )
    }

    private func streak(for habit: Habit) -> Int {
        guard habit.kind == .habit else { return 0 }

        if !habit.isGoalMet(by: count(for: habit)) {
            return HabitStreakCalculator.streakBefore(
                selectedDate,
                for: habit,
                completedIdentifiers: completedIdentifiers,
                calendar: calendar
            )
        }

        return HabitStreakCalculator.streak(
            for: habit,
            through: selectedDate,
            completedIdentifiers: completedIdentifiers,
            calendar: calendar
        )
    }

    private var canChangeCompletion: Bool {
        HabitDayPolicy.canChangeStatus(on: selectedDate, calendar: calendar)
    }

    private func toggleCompletion(for habit: Habit) {
        setCompletion(!isCompleted(habit), for: habit)
    }

    private func setCompletion(_ isCompleted: Bool, for habit: Habit) {
        setCount(isCompleted ? 1 : 0, for: habit)
    }

    private func setCount(_ count: Int, for habit: Habit) {
        guard canChangeCompletion else { return }

        let identifier = completionIdentifier(for: habit)
        let previousCount = self.count(for: habit)

        do {
            try HabitCompletionStore.setCount(
                count,
                habit: habit,
                date: selectedDate,
                calendar: calendar,
                context: modelContext
            )

            if HabitDaySorter.movesToCompletedSection(
                habit,
                from: previousCount,
                to: count
            ) {
                delayCompletedSectionMove(for: habit, previousCount: previousCount)
            }

            onCountChanged(identifier, count)
        } catch {
            modelContext.rollback()
            persistenceError = error.localizedDescription
        }
    }

    private func delayCompletedSectionMove(for habit: Habit, previousCount: Int) {
        completionMoveState.scheduleMove(
            for: habit.identifier,
            previousCount: previousCount,
            reduceMotion: accessibilityReduceMotion
        )
    }

    private func completionIdentifier(for habit: Habit) -> String {
        HabitCompletionPeriod.identifier(
            for: habit,
            containing: selectedDate,
            calendar: calendar
        )
    }
}
