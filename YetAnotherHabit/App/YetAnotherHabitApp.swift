import SwiftData
import SwiftUI

@main
struct YetAnotherHabitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppPreferenceKey.theme) private var appTheme = AppTheme.system
    @AppStorage(AppPreferenceKey.language) private var appLanguage = AppLanguage.system
    @AppStorage(AppPreferenceKey.faceIDEnabled) private var faceIDEnabled = false
    @State private var persistence = PersistenceController()
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
                        Label(
                            "Не удалось открыть данные",
                            systemImage: "externaldrive.badge.exclamationmark"
                        )
                    } description: {
                        Text(
                            persistence.errorMessage
                                ?? AppLocalization.string(
                                    "Попробуйте ещё раз.",
                                    locale: appLanguage.locale
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
            .environment(appDataState)
            .environment(appLock)
            .preferredColorScheme(appTheme.colorScheme)
            .environment(\.locale, appLanguage.locale)
            .task {
                await updateLockState()
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
            _ = await appLock.authenticate(locale: appLanguage.locale)
        } else {
            appLock.unlockWithoutAuthentication()
        }
    }
}
