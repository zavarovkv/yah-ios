import CloudKit
import Observation

@MainActor
@Observable
final class CloudSyncStatus {
    enum State {
        case checking
        case available
        case noAccount
        case restricted
        case unavailable
        case localOnly
    }

    private(set) var state: State = .checking

    func refresh() async {
#if targetEnvironment(simulator)
        state = .localOnly
#else
        do {
            switch try await CKContainer(identifier: "iCloud.KZ.YetAnotherHabit").accountStatus() {
            case .available:
                state = .available
            case .noAccount:
                state = .noAccount
            case .restricted:
                state = .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                state = .unavailable
            @unknown default:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
#endif
    }
}
