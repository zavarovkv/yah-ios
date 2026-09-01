import SwiftUI

private enum HabitRoute: Hashable {
    case analytics(UUID)
    case edit(UUID)
}

struct HabitsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(AppDataState.self) private var appDataState
    let data: HabitPresentationData
    let onTabBarScrollDirectionChanged: (Bool) -> Void
    let onTabBarScrollInteractionEnded: () -> Void
    @AppStorage(AppPreferenceKey.completedHabitsSectionExpanded)
    private var prefersCompletedSectionExpanded = true
    @AppStorage(AppPreferenceKey.countersSectionExpanded)
    private var prefersCountersSectionExpanded = true

    @State private var selectedDate = Date.now
    @State private var displayedWeekStart = WeekCalendar.startOfWeek(containing: .now)
    @State private var isCreatingHabit = false
    @State private var persistenceError: String?
    @State private var returnTransitionEdge: Edge = .trailing
    @State private var dayTransitionID = 0
    @State private var calendarTransitionID = 0
    @State private var presentedRoute: HabitRoute?
    @State private var nestedEditHabitIdentifier: UUID?
    @State private var isDayContentAtTop = true
    @State private var calendarScrollOffset: CGFloat = 0
    @State private var pullInteractionState = HabitsPullInteractionState()
    @State private var hasInitializedCalendar = false
    @State private var isDayNavigationActive = false
    @State private var showsDayScrollIndicator = true
    @State private var scrollIndicatorRestoreID = 0

    private let emptyReturnPullThreshold: CGFloat = 84
    private let listReturnPullThreshold: CGFloat = 60
    private let pullIndicatorRevealDistance: CGFloat = 32
    private let pullIndicatorContentHeight: CGFloat = 24
    private let calendarHeaderHeight: CGFloat = 96
    private let calendarExitFadeDistance: CGFloat = 52
    private let maximumPullIndicatorHeight: CGFloat = 72

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    dayContent
                        .offset(y: scheduledHabits.isEmpty ? pullIndicatorHeight : 0)
                        .id(dayTransitionID)
                        .transition(.push(from: returnTransitionEdge))

                    calendarContent
                        .frame(height: calendarHeaderHeight, alignment: .top)
                        .offset(y: -calendarScrollOffset)
                        .opacity(calendarExitOpacity)
                        .id(calendarTransitionID)
                        .transition(.push(from: returnTransitionEdge))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HabitsPullIndicator(
                    state: pullInteractionState,
                    action: pullAction,
                    returnToTodaySystemImage: returnToTodaySystemImage,
                    threshold: returnPullThreshold,
                    revealDistance: pullIndicatorRevealDistance,
                    contentHeight: pullIndicatorContentHeight,
                    maximumHeight: maximumPullIndicatorHeight,
                    isEmptyState: scheduledHabits.isEmpty
                )
                    .offset(y: calendarHeaderHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .contentShape(Rectangle())
            .simultaneousGesture(pullActionGesture)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: returnToToday) {
                        Text(
                            DateTitleFormatter.title(
                                for: selectedDate,
                                calendar: calendar,
                                locale: locale
                            )
                        )
                        .font(.headline)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Вернуться к сегодняшней дате")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreatingHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить привычку")
                }
            }
            .navigationDestination(isPresented: $isCreatingHabit) {
                NewHabitView(selectedDate: selectedDate) { habit in
                    appDataState.recordAdded(habit)
                }
            }
            .navigationDestination(item: $presentedRoute, destination: habitDestination)
            .onAppear(perform: initializeCalendar)
            .task(id: scrollIndicatorRestoreID, restoreDayScrollIndicator)
            .saveErrorAlert($persistenceError)
        }
        .modifier(HabitsTabBarBackground())
    }

    @ViewBuilder
    private var dayContent: some View {
        if scheduledHabits.isEmpty {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: calendarHeaderHeight)

                ZStack {
                    Color.clear

                    ContentUnavailableView {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 44, weight: .regular))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(emptyStateForegroundColor)
                            .accessibilityHidden(true)
                    } description: {
                        Text(emptyStateMessage)
                            .font(.body)
                            .foregroundStyle(emptyStateForegroundColor)
                            .multilineTextAlignment(.center)
                    } actions: {
                        Button("Добавить", systemImage: "plus") {
                            isCreatingHabit = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .tint(.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                isDayContentAtTop = true
                calendarScrollOffset = 0
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        } else {
            HabitDayListView(
                habits: scheduledHabits,
                selectedDate: selectedDate,
                completionCounts: completionCounts,
                completedIdentifiers: completedIdentifiers,
                onCountChanged: recordCountChange,
                onOpenHabit: { presentedRoute = .analytics($0) },
                onEditHabit: { presentedRoute = .edit($0) },
                onScrollTopChanged: { isDayContentAtTop = $0 },
                onScrollOffsetChanged: { offset in
                    guard calendarScrollOffset != offset else { return }
                    calendarScrollOffset = offset
                },
                onTabBarScrollDirectionChanged: onTabBarScrollDirectionChanged,
                onTabBarScrollInteractionEnded: onTabBarScrollInteractionEnded,
                onPullChanged: handleListPullChanged,
                onPullEnded: handleListPullEnded,
                onPullRebounded: handleListPullRebounded,
                topInset: calendarHeaderHeight,
                pullReboundCompletionDistance: canReturnToToday ? 12 : 0.5,
                showsScrollIndicator: showsDayScrollIndicator,
                prefersCompletedSectionExpanded: $prefersCompletedSectionExpanded,
                prefersCountersSectionExpanded: $prefersCountersSectionExpanded,
                persistenceError: $persistenceError
            )
            .id(WeekCalendar.dayKey(for: selectedDate, calendar: calendar))
        }
    }

    private var calendarContent: some View {
        WeekCalendarPagerView(
            displayedWeekStart: $displayedWeekStart,
            selectedDate: $selectedDate,
            progressByDayKey: progressByDayKey,
            onNavigationInteractionChanged: handleDayNavigationInteractionChanged
        )
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var calendarExitOpacity: Double {
        let fadeStart = max(
            calendarHeaderHeight - calendarExitFadeDistance,
            0
        )
        let linearProgress = min(
            max(
                (calendarScrollOffset - fadeStart) / calendarExitFadeDistance,
                0
            ),
            1
        )
        let smoothProgress = linearProgress * linearProgress * (3 - 2 * linearProgress)
        return Double(1 - smoothProgress)
    }

    private var emptyStateMessage: LocalizedStringKey {
        displayedHabits.isEmpty
            ? "Создайте первую привычку, чтобы начать."
            : "На этот день привычек нет."
    }

    private var emptyStateForegroundColor: Color {
        Color.accentColor.opacity(0.52)
    }

    @ViewBuilder
    private func habitDestination(_ route: HabitRoute) -> some View {
        switch route {
        case .analytics(let identifier):
            if let habit = habit(with: identifier) {
                HabitAnalyticsView(habit: habit) {
                    nestedEditHabitIdentifier = identifier
                }
                .navigationDestination(item: $nestedEditHabitIdentifier) {
                    editDestination(identifier: $0)
                }
            } else {
                missingHabitView
            }
        case .edit(let identifier):
            if let habit = habit(with: identifier) {
                EditHabitView(habit: habit, onDeleted: handleHabitDeleted)
            } else {
                missingHabitView
            }
        }
    }

    @ViewBuilder
    private func editDestination(identifier: UUID) -> some View {
        if let habit = habit(with: identifier) {
            EditHabitView(habit: habit, onDeleted: handleHabitDeleted)
        } else {
            missingHabitView
        }
    }

    private var missingHabitView: some View {
        ContentUnavailableView(
            "Привычка не найдена",
            systemImage: "exclamationmark.triangle"
        )
    }

    private func habit(with identifier: UUID) -> Habit? {
        displayedHabits.first { $0.identifier == identifier }
    }

    private func handleHabitDeleted(_ identifier: UUID) {
        appDataState.recordDeleted(identifier: identifier)
        nestedEditHabitIdentifier = nil
        presentedRoute = nil
    }

    private var scheduledHabits: [Habit] {
        displayedHabits.filter {
            $0.isScheduled(on: selectedDate, calendar: calendar)
        }
    }

    private var displayedHabits: [Habit] {
        data.habits
    }

    private var progressByDayKey: [String: Double] {
        let today = calendar.startOfDay(for: .now)
        let visibleDates = (-1...1)
            .compactMap {
                WeekCalendar.addWeeks(
                    $0,
                    to: displayedWeekStart,
                    calendar: calendar
                )
            }
            .flatMap { WeekCalendar.dates(starting: $0, calendar: calendar) }

        return visibleDates.reduce(into: [:]) { result, date in
                guard calendar.startOfDay(for: date) <= today else { return }

                let dayKey = WeekCalendar.dayKey(for: date, calendar: calendar)
                result[dayKey] = HabitProgressCalculator.progress(
                    for: date,
                    habits: displayedHabits,
                    completedIdentifiers: completedIdentifiers,
                    calendar: calendar
                )
            }
    }

    private var completedIdentifiers: Set<String> {
        data.completedIdentifiers
    }

    private var completionCounts: [String: Int] {
        data.completionCounts
    }

    private func recordCountChange(identifier: String, count: Int) {
        appDataState.recordCount(identifier: identifier, count: count)
    }

    private func returnToToday() {
        let today = Date.now
        let todayWeekStart = WeekCalendar.startOfWeek(containing: today, calendar: calendar)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let todayDay = calendar.startOfDay(for: today)
        let isAlreadyShowingToday = selectedDay == todayDay
            && calendar.isDate(displayedWeekStart, inSameDayAs: todayWeekStart)

        guard !isAlreadyShowingToday else { return }

        let isReturningFromFuture = selectedDay > todayDay
            || (selectedDay == todayDay && displayedWeekStart > todayWeekStart)
        let isChangingWeek = !calendar.isDate(
            displayedWeekStart,
            inSameDayAs: todayWeekStart
        )
        returnTransitionEdge = isReturningFromFuture ? .leading : .trailing

        let animation: Animation = accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .snappy(duration: 0.35)
        handleDayNavigationInteractionChanged(true)
        withAnimation(animation) {
            selectedDate = today
            displayedWeekStart = todayWeekStart
            calendarScrollOffset = 0
            dayTransitionID += 1
            if isChangingWeek {
                calendarTransitionID += 1
            }
        }
        handleDayNavigationInteractionChanged(false)
    }

    private func handleDayNavigationInteractionChanged(_ isActive: Bool) {
        isDayNavigationActive = isActive
        showsDayScrollIndicator = false
        scrollIndicatorRestoreID += 1
    }

    private func restoreDayScrollIndicator() async {
        guard !isDayNavigationActive, !showsDayScrollIndicator else { return }

        do {
            try await Task.sleep(
                for: .milliseconds(accessibilityReduceMotion ? 120 : 280)
            )
        } catch {
            return
        }

        guard !Task.isCancelled, !isDayNavigationActive else { return }
        showsDayScrollIndicator = true
    }

    private var canReturnToToday: Bool {
        let today = calendar.startOfDay(for: .now)
        return calendar.startOfDay(for: selectedDate) != today
            || !calendar.isDate(
                displayedWeekStart,
                inSameDayAs: WeekCalendar.startOfWeek(containing: today, calendar: calendar)
            )
    }

    private var returnToTodaySystemImage: String {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let today = calendar.startOfDay(for: .now)
        if selectedDay != today {
            return selectedDay > today ? "arrow.left" : "arrow.right"
        }

        let todayWeekStart = WeekCalendar.startOfWeek(
            containing: today,
            calendar: calendar
        )
        return displayedWeekStart > todayWeekStart ? "arrow.left" : "arrow.right"
    }

    private var returnPullThreshold: CGFloat {
        scheduledHabits.isEmpty ? emptyReturnPullThreshold : listReturnPullThreshold
    }

    private var pullIndicatorHeight: CGFloat {
        guard displayedPullAction != nil else { return 0 }

        let distanceBeforeThreshold = min(pullInteractionState.distance, returnPullThreshold)
        let distanceAfterThreshold = max(
            pullInteractionState.distance - returnPullThreshold,
            0
        )
        let resistedDistance = distanceBeforeThreshold * 0.68
            + distanceAfterThreshold * 0.16
        return min(max(resistedDistance, 0), maximumPullIndicatorHeight)
    }

    private var pullActionGesture: some Gesture {
        // Pull-to-refresh would communicate a data refresh and display a spinner.
        // SwiftUI has no native pull gesture for navigation, so this scoped drag
        // preserves the requested return-to-today interaction without false UI.
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                guard scheduledHabits.isEmpty else { return }

                let translation = value.translation
                let availableAction = pullInteractionState.startDistance == nil
                    ? pullAction
                    : pullInteractionState.actionSnapshot
                guard
                    availableAction != nil,
                    isDayContentAtTop,
                    translation.height > 0,
                    abs(translation.height) > abs(translation.width)
                else {
                    resetReturnPull()
                    return
                }

                if pullInteractionState.startDistance == nil {
                    pullInteractionState.startDistance = translation.height
                    pullInteractionState.actionSnapshot = availableAction
                }
                let pullDistance = max(
                    translation.height
                        - (pullInteractionState.startDistance ?? translation.height),
                    0
                )
                pullInteractionState.distance = pullDistance
                updatePullReadiness(
                    for: pullDistance,
                    threshold: emptyReturnPullThreshold
                )
            }
            .onEnded { value in
                guard scheduledHabits.isEmpty else { return }

                let translation = value.translation
                let action = pullInteractionState.actionSnapshot
                let shouldPerform = action != nil
                    && isDayContentAtTop
                    && pullInteractionState.isReady
                    && abs(translation.height) > abs(translation.width)

                if shouldPerform, let action {
                    finishPullAction(action)
                } else {
                    resetReturnPull()
                }
            }
    }

    private func handleListPullChanged(_ distance: CGFloat) {
        if pullInteractionState.actionSnapshot == nil, distance > 0 {
            pullInteractionState.actionSnapshot = pullAction
        }
        guard pullInteractionState.actionSnapshot != nil else {
            pullInteractionState.distance = 0
            pullInteractionState.isReady = false
            return
        }

        pullInteractionState.distance = distance
        updatePullReadiness(for: distance, threshold: listReturnPullThreshold)
    }

    private func updatePullReadiness(for distance: CGFloat, threshold: CGFloat) {
        if !pullInteractionState.isReady, distance >= threshold {
            pullInteractionState.feedbackTrigger += 1
            pullInteractionState.isReady = true
        } else if pullInteractionState.isReady, distance < threshold - 12 {
            pullInteractionState.isReady = false
        }
    }

    private func handleListPullEnded() {
        if pullInteractionState.isReady,
           let action = pullInteractionState.actionSnapshot {
            pullInteractionState.pendingAction = action
        } else {
            pullInteractionState.pendingAction = nil
        }
        resetReturnPull()
    }

    private func handleListPullRebounded() {
        guard let action = pullInteractionState.pendingAction else { return }

        pullInteractionState.pendingAction = nil
        performPullAction(action)
    }

    private var displayedPullAction: HabitsPullAction? {
        pullInteractionState.actionSnapshot ?? pullAction
    }

    private var pullAction: HabitsPullAction? {
        canReturnToToday ? .returnToToday : nil
    }

    private func finishPullAction(_ action: HabitsPullAction) {
        resetReturnPull()
        performPullAction(action)
    }

    private func performPullAction(_ action: HabitsPullAction) {
        switch action {
        case .returnToToday:
            returnToToday()
        }
    }

    private func resetReturnPull() {
        pullInteractionState.startDistance = nil
        pullInteractionState.actionSnapshot = nil
        let animation: Animation = accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .smooth(duration: 0.18)
        withAnimation(animation) {
            pullInteractionState.distance = 0
            pullInteractionState.isReady = false
        }
    }

    private func initializeCalendar() {
        guard !hasInitializedCalendar else { return }

        let today = Date.now
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selectedDate = today
            displayedWeekStart = WeekCalendar.startOfWeek(
                containing: today,
                calendar: calendar
            )
            hasInitializedCalendar = true
        }
    }

}

private struct HabitsTabBarBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .toolbarBackground(.hidden, for: .tabBar)
        } else {
            content
        }
    }
}
