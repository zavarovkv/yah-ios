import SwiftData
import SwiftUI

private enum AppTab: Hashable {
    case habits
    case progress
    case profile
}

struct ContentView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDataState.self) private var appDataState
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(filter: #Predicate<HabitCompletion> { $0.isCompleted })
    private var completions: [HabitCompletion]
    @State private var maintenanceError: String?
    @State private var selectedTab = AppTab.habits

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .habits) {
                HabitsView()
            } label: {
                Label {
                    Text("Привычки")
                } icon: {
                    animatedSymbol(
                        "checkmark.circle",
                        selectedSystemImage: "checkmark.circle.fill",
                        tab: .habits
                    )
                }
            }
            .badge(incompleteHabitCount)

            Tab(value: .progress) {
                ProgressScreen()
            } label: {
                Label {
                    Text("Прогресс")
                } icon: {
                    animatedSymbol(
                        "chart.bar",
                        selectedSystemImage: "chart.bar.fill",
                        tab: .progress
                    )
                }
            }

            Tab(value: .profile) {
                SettingsView()
            } label: {
                Label {
                    Text("Вы")
                } icon: {
                    ProfileAvatarView(data: profiles.first?.avatarData, size: 24)
                        .scaleEffect(selectedTab == .profile ? 1.1 : 1)
                        .animation(
                            .bouncy(duration: 0.25, extraBounce: 0.08),
                            value: selectedTab
                        )
                }
            }
        }
        .task {
            do {
                try DataMaintenance.reconcile(
                    context: modelContext,
                    calendar: calendar,
                    locale: locale
                )
            } catch {
                maintenanceError = error.localizedDescription
            }
        }
        .appErrorAlert("Не удалось подготовить данные", error: $maintenanceError)
    }

    private var incompleteHabitCount: Int {
        let today = calendar.startOfDay(for: .now)
        let visibleHabits = appDataState.visibleHabits(from: habits)
        let counts = appDataState.visibleCompletionCounts(
            from: HabitCompletionIndex.counts(in: completions)
        )

        return HabitDaySorter.incompleteCount(
            in: visibleHabits,
            for: today,
            completionCounts: counts,
            calendar: calendar
        )
    }

    private func animatedSymbol(
        _ systemImage: String,
        selectedSystemImage: String,
        tab: AppTab
    ) -> some View {
        Image(systemName: selectedTab == tab ? selectedSystemImage : systemImage)
            .scaleEffect(selectedTab == tab ? 1.1 : 1)
            .animation(
                .bouncy(duration: 0.25, extraBounce: 0.08),
                value: selectedTab
            )
    }
}

#Preview {
    ContentView()
        .environment(AppDataState())
        .environment(AppLockController())
        .modelContainer(
            for: [Habit.self, HabitCompletion.self, UserProfile.self],
            inMemory: true
        )
}
