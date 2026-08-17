import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PersistenceController {
    private(set) var container: ModelContainer?
    private(set) var errorMessage: String?

    init() {
        load()
    }

    func retry() {
        load()
    }

    private func load() {
        do {
            container = try Self.makeContainer()
            errorMessage = nil
        } catch {
            container = nil
            errorMessage = error.localizedDescription
        }
    }

    private static func makeContainer() throws -> ModelContainer {
        let environment = ProcessInfo.processInfo.environment
        let isPreview = environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"

#if targetEnvironment(simulator)
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
#else
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isPreview
            ? .none
            : .automatic
#endif

        let schema = Schema([
            Habit.self,
            HabitCompletion.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isPreview,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: configuration)
    }
}
