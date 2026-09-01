import Foundation
import LocalAuthentication
import Testing
@testable import YetAnotherHabit

@MainActor
struct AppLockControllerTests {
    @Test
    func successfulAuthenticationUnlocksAndClearsTransientState() async {
        let context = StubAuthenticationContext(
            biometryType: .faceID,
            canEvaluate: true,
            evaluationResult: true
        )
        let controller = AppLockController { context }

        #expect(controller.verifyFaceIDAvailability(locale: Locale(identifier: "en")))
        #expect(await controller.authenticate(locale: Locale(identifier: "en")))
        #expect(controller.isUnlocked)
        #expect(!controller.isAuthenticating)
        #expect(controller.errorMessage == nil)
        #expect(context.localizedCancelTitle == "Cancel")
        #expect(context.evaluatedPolicies == [.deviceOwnerAuthentication])
    }

    @Test
    func unavailableFaceIDKeepsApplicationLocked() {
        let context = StubAuthenticationContext(
            biometryType: .touchID,
            canEvaluate: true,
            evaluationResult: true
        )
        let controller = AppLockController { context }

        #expect(!controller.verifyFaceIDAvailability(locale: Locale(identifier: "en")))
        #expect(!controller.isUnlocked)
        #expect(controller.errorMessage == "Face ID is unavailable or not set up on this device.")
    }

    @Test
    func failedOwnerAuthenticationSurfacesLocalizedError() async {
        let context = StubAuthenticationContext(
            biometryType: .faceID,
            canEvaluate: false,
            evaluationResult: false
        )
        let controller = AppLockController { context }

        let didAuthenticate = await controller.authenticate(locale: Locale(identifier: "en"))

        #expect(!didAuthenticate)
        #expect(!controller.isUnlocked)
        #expect(!controller.isAuthenticating)
        #expect(controller.errorMessage == "Device owner authentication is unavailable.")
    }

    @Test
    func lockClearsSensitiveStateAfterAuthentication() async {
        let context = StubAuthenticationContext(
            biometryType: .faceID,
            canEvaluate: true,
            evaluationResult: true
        )
        let controller = AppLockController { context }

        #expect(await controller.authenticate(locale: Locale(identifier: "en")))
        controller.lock()

        #expect(!controller.isUnlocked)
        #expect(!controller.isAuthenticating)
        #expect(controller.errorMessage == nil)
    }
}

@MainActor
private final class StubAuthenticationContext: AppAuthenticationContext {
    let biometryType: LABiometryType
    var localizedCancelTitle: String?
    private let canEvaluate: Bool
    private let evaluationResult: Bool
    private(set) var evaluatedPolicies: [LAPolicy] = []

    init(
        biometryType: LABiometryType,
        canEvaluate: Bool,
        evaluationResult: Bool
    ) {
        self.biometryType = biometryType
        self.canEvaluate = canEvaluate
        self.evaluationResult = evaluationResult
    }

    func canEvaluatePolicy(_ policy: LAPolicy) -> Bool {
        canEvaluate
    }

    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async throws -> Bool {
        evaluatedPolicies.append(policy)
        return evaluationResult
    }

    func invalidate() {}
}
