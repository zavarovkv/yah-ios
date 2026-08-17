import SwiftData
import SwiftUI

@main
struct YetAnotherHabitApp: App {
    @State private var persistence = PersistenceController()
    @State private var cloudSyncStatus = CloudSyncStatus()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = persistence.container {
                    ContentView()
                        .modelContainer(container)
                } else {
                    ContentUnavailableView {
                        Label("Не удалось открыть данные", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(persistence.errorMessage ?? String(localized: "Попробуйте ещё раз."))
                    } actions: {
                        Button("Повторить") {
                            persistence.retry()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .environment(cloudSyncStatus)
            .task {
                await cloudSyncStatus.refresh()
            }
        }
    }
}
