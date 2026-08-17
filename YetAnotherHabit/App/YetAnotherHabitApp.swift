import SwiftData
import SwiftUI

@main
struct YetAnotherHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.russian.rawValue
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @State private var persistence = PersistenceController()
    @State private var cloudSyncStatus = CloudSyncStatus()
    @State private var appDataState = AppDataState()
    @State private var appLock = AppLockController()

    var body: some Scene {
        WindowGroup {
            Group {
                if faceIDEnabled, !appLock.isUnlocked {
                    AppLockView()
                } else if let container = persistence.container {
                    ContentView()
                        .modelContainer(container)
                } else {
                    ContentUnavailableView {
                        Label("Не удалось открыть данные", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(
                            persistence.errorMessage
                                ?? String(
                                    localized: "Попробуйте ещё раз.",
                                    locale: AppLanguage.selectedLocale
                                )
                        )
                    } actions: {
                        Button("Повторить") {
                            persistence.retry()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .environment(cloudSyncStatus)
            .environment(appDataState)
            .environment(appLock)
            .preferredColorScheme(
                AppTheme(rawValue: appTheme)?.colorScheme
            )
            .environment(
                \.locale,
                AppLanguage(rawValue: appLanguage)?.locale ?? AppLanguage.russian.locale
            )
            .task {
                await updateLockState()
                await cloudSyncStatus.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .inactive, .background:
                    if faceIDEnabled { appLock.lock() }
                case .active:
                    Task { await updateLockState() }
                @unknown default:
                    break
                }
            }
            .onChange(of: faceIDEnabled) {
                Task { await updateLockState() }
            }
        }
    }

    private func updateLockState() async {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            appLock.unlockWithoutAuthentication()
            return
        }

        if faceIDEnabled {
            guard !appLock.isUnlocked else { return }
            _ = await appLock.authenticate()
        } else {
            appLock.unlockWithoutAuthentication()
        }
    }
}
