import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var modelContext
    @State private var maintenanceError: String?

    var body: some View {
        TabView {
            Tab("Привычки", systemImage: "checkmark.circle") {
                HabitsView()
            }

            Tab("Прогресс", systemImage: "chart.bar") {
                ProgressScreen()
            }

            Tab("Друзья", systemImage: "person.2") {
                FriendsView()
            }

            Tab("Настройки", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .task {
            do {
                try DataMaintenance.reconcile(context: modelContext, calendar: calendar)
            } catch {
                maintenanceError = error.localizedDescription
            }
        }
        .appErrorAlert("Не удалось подготовить данные", error: $maintenanceError)
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
