import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.theme) private var appTheme = AppTheme.system
    @AppStorage(AppPreferenceKey.language) private var appLanguage = AppLanguage.system
    @AppStorage(AppPreferenceKey.faceIDEnabled) private var faceIDEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(AppLockController.self) private var appLock
    let profiles: [UserProfile]
    @State private var createdProfile: UserProfile?
    @State private var profileCreationError: String?
    @State private var isPresentingProfile = false
    @State private var isUpdatingFaceID = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first ?? createdProfile {
                    VStack(spacing: 0) {
                        Button {
                            isPresentingProfile = true
                        } label: {
                            profileSummary(profile)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)

                        Form {
                            appearanceSection
                            securitySection
                            aboutSection
                        }
                        .scrollContentBackground(.hidden)
                        .contentMargins(.top, 0, for: .scrollContent)
                        .listSectionSpacing(12)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isPresentingProfile = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .accessibilityLabel("Редактировать профиль")
                        }
                    }
                    .navigationDestination(isPresented: $isPresentingProfile) {
                        ProfileSettingsView(profile: profile)
                    }
                } else if let profileCreationError {
                    ContentUnavailableView {
                        Label(
                            "Не удалось открыть настройки",
                            systemImage: "exclamationmark.triangle"
                        )
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
            .onChange(of: profiles.count, initial: true) {
                reconcileProfilesIfNeeded()
            }
        }
        .appErrorAlert("Не удалось изменить настройки", error: $errorMessage)
    }

    private func profileSummary(_ profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            profileAvatar(profile)

            Text(profileDisplayName(profile))
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func profileAvatar(_ profile: UserProfile) -> some View {
        ProfileAvatarView(data: profile.avatarData, size: 112)
    }

    private func profileDisplayName(_ profile: UserProfile) -> String {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty
            ? AppLocalization.string("Имя не указано", locale: locale)
            : name
    }

    private var appearanceSection: some View {
        Section("Оформление") {
            Picker("Тема", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.menu)

            Picker("Язык", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var securitySection: some View {
        Section("Безопасность") {
            Toggle("Вход по Face ID", isOn: faceIDBinding)
                .disabled(isUpdatingFaceID)
        }
    }

    private var aboutSection: some View {
        Section("О приложении") {
            Text(
                "Yet Another Habit помогает формировать полезные привычки и отслеживать прогресс."
            )
                .foregroundStyle(.secondary)

            LabeledContent("Версия", value: appVersion)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        guard let build, !build.isEmpty, build != version else {
            return version
        }
        return "\(version) (\(build))"
    }

    private var faceIDBinding: Binding<Bool> {
        Binding(
            get: { faceIDEnabled },
            set: { shouldEnable in
                if shouldEnable {
                    Task { await enableFaceID() }
                } else {
                    faceIDEnabled = false
                    appLock.unlockWithoutAuthentication()
                }
            }
        )
    }

    private func enableFaceID() async {
        isUpdatingFaceID = true
        defer { isUpdatingFaceID = false }

        guard appLock.verifyFaceIDAvailability(locale: locale) else {
            faceIDEnabled = false
            errorMessage = appLock.errorMessage
            return
        }

        if await appLock.authenticate(locale: locale) {
            faceIDEnabled = true
        } else {
            faceIDEnabled = false
            errorMessage = appLock.errorMessage
        }
    }

    private func createProfileIfNeeded() {
        guard profiles.isEmpty, createdProfile == nil else { return }
        profileCreationError = nil

        let profile = UserProfile(
            name: UserProfileReconciler.generatedName(locale: locale)
        )
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
        let primary = UserProfileReconciler.reconcile(
            profiles,
            in: modelContext,
            locale: locale
        )

        do {
            try modelContext.save()
            createdProfile = primary
        } catch {
            modelContext.rollback()
            profileCreationError = error.localizedDescription
        }
    }
}
