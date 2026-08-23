import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockController {
    private(set) var isUnlocked = false
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?
    @ObservationIgnored private var authenticationTask: Task<Bool, Never>?
    @ObservationIgnored private var authenticationContext: LAContext?
    @ObservationIgnored private var authenticationAttemptID: UUID?

    func lock() {
        authenticationContext?.invalidate()
        authenticationContext = nil
        authenticationTask?.cancel()
        authenticationTask = nil
        authenticationAttemptID = nil
        isAuthenticating = false
        isUnlocked = false
        errorMessage = nil
    }

    func unlockWithoutAuthentication() {
        isUnlocked = true
        errorMessage = nil
    }

    func authenticate(locale: Locale) async -> Bool {
        if let authenticationTask {
            return await authenticationTask.value
        }

        isAuthenticating = true
        let attemptID = UUID()
        authenticationAttemptID = attemptID
        let task = Task {
            await performAuthentication(locale: locale, attemptID: attemptID)
        }
        authenticationTask = task
        let result = await task.value
        if authenticationAttemptID == attemptID {
            authenticationTask = nil
            authenticationAttemptID = nil
            isAuthenticating = false
        }
        return result
    }

    func verifyFaceIDAvailability(locale: Locale) -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error),
              context.biometryType == .faceID
        else {
            errorMessage = AppLocalization.string(
                "Face ID недоступен или не настроен на этом устройстве.",
                locale: locale
            )
            isUnlocked = false
            return false
        }

        errorMessage = nil
        return true
    }

    private func performAuthentication(locale: Locale, attemptID: UUID) async -> Bool {
        let context = LAContext()
        authenticationContext = context
        defer {
            if authenticationContext === context {
                authenticationContext = nil
            }
        }
        context.localizedCancelTitle = AppLocalization.string("Отмена", locale: locale)
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = AppLocalization.string(
                "Не удалось выполнить проверку владельца устройства.",
                locale: locale
            )
            isUnlocked = false
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: AppLocalization.string(
                    "Разблокируйте приложение",
                    locale: locale
                )
            )
            guard
                !Task.isCancelled,
                authenticationAttemptID == attemptID
            else {
                return false
            }
            isUnlocked = success
            errorMessage = success ? nil : AppLocalization.string(
                "Не удалось подтвердить Face ID.",
                locale: locale
            )
            return success
        } catch {
            guard authenticationAttemptID == attemptID else { return false }
            isUnlocked = false
            errorMessage = authenticationErrorMessage(for: error)
            return false
        }
    }

    private func authenticationErrorMessage(for error: Error) -> String? {
        guard let authenticationError = error as? LAError else {
            return error.localizedDescription
        }

        switch authenticationError.code {
        case .appCancel, .systemCancel, .userCancel:
            return nil
        default:
            return authenticationError.localizedDescription
        }
    }
}
