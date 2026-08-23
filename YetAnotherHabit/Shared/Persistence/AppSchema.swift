import SwiftData

enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AppSchemaV1.Habit.self, AppSchemaV1.HabitCompletion.self, AppSchemaV1.UserProfile.self]
    }
}

enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AppSchemaV2.Habit.self, AppSchemaV2.HabitCompletion.self, AppSchemaV2.UserProfile.self]
    }
}

enum AppSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AppSchemaV3.Habit.self, AppSchemaV3.HabitCompletion.self, AppSchemaV2.UserProfile.self]
    }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self, AppSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: AppSchemaV1.self, toVersion: AppSchemaV2.self),
            .lightweight(fromVersion: AppSchemaV2.self, toVersion: AppSchemaV3.self)
        ]
    }
}
