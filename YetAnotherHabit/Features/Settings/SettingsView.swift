import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @State private var createdProfile: UserProfile?
    @State private var profileCreationError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first ?? createdProfile {
                    ProfileSettingsView(profile: profile)
                } else if let profileCreationError {
                    ContentUnavailableView {
                        Label("Не удалось открыть настройки", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(profileCreationError)
                    } actions: {
                        Button("Повторить") {
                            createProfileIfNeeded()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ProgressView()
                        .task {
                            createProfileIfNeeded()
                        }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: profiles.count, initial: true) {
                reconcileProfilesIfNeeded()
            }
        }
    }

    private func createProfileIfNeeded() {
        guard profiles.isEmpty, createdProfile == nil else { return }
        profileCreationError = nil

        let profile = UserProfile()
        modelContext.insert(profile)

        do {
            try modelContext.save()
            createdProfile = profile
        } catch {
            modelContext.rollback()
            profileCreationError = error.localizedDescription
        }
    }

    private func reconcileProfilesIfNeeded() {
        guard profiles.count > 1 else { return }
        let primary = UserProfileReconciler.reconcile(profiles, in: modelContext)

        do {
            try modelContext.save()
            createdProfile = primary
        } catch {
            modelContext.rollback()
            profileCreationError = error.localizedDescription
        }
    }
}
