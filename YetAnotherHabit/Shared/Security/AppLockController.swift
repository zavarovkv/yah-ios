import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockController {
    private(set) var isUnlocked = false
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?
    @ObservationIgnored private var authenticationTask: Task<Bool, Never>?

    func lock() { isUnlocked = false }

    func unlockWithoutAuthentication() {
        isUnlocked = true
        errorMessage = nil
    }

    func authenticate() async -> Bool {
        if let authenticationTask {
            return await authenticationTask.value
        }

        isAuthenticating = true
        let task = Task { await performAuthentication() }
        authenticationTask = task
        let result = await task.value
        authenticationTask = nil
        isAuthenticating = false
        return result
    }

    func verifyFaceIDAvailability() -> Bool {
        let context = LAContext()
        let locale = AppLanguage.selectedLocale
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error),
              context.biometryType == .faceID
        else {
            errorMessage = String(localized: "Face ID недоступен или не настроен на этом устройстве.", locale: locale)
            isUnlocked = false
            return false
        }

        errorMessage = nil
        return true
    }

    private func performAuthentication() async -> Bool {
        let context = LAContext()
        let locale = AppLanguage.selectedLocale
        context.localizedCancelTitle = String(localized: "Отмена", locale: locale)
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = String(localized: "Не удалось выполнить проверку владельца устройства.", locale: locale)
            isUnlocked = false
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Разблокируйте приложение", locale: locale)
            )
            isUnlocked = success
            errorMessage = success ? nil : String(localized: "Не удалось подтвердить Face ID.", locale: locale)
            return success
        } catch {
            isUnlocked = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
