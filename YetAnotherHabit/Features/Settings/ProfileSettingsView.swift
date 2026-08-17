import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ProfileSettingsView: View {
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.russian.rawValue
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Environment(CloudSyncStatus.self) private var cloudSyncStatus
    @Environment(AppLockController.self) private var appLock
    @Bindable var profile: UserProfile

    @State private var draftName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var isUpdatingFaceID = false
    @State private var errorMessage: String?
    @State private var avatarTask: Task<Void, Never>?
    @FocusState private var isNameFocused: Bool

    init(profile: UserProfile) {
        self.profile = profile
        _draftName = State(initialValue: profile.name)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    avatarMenu
                    Spacer()
                }
                .listRowInsets(
                    EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )
                .listRowBackground(Color.clear)
            }

            Section {
                TextField("Имя", text: $draftName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit(saveNameIfNeeded)
            }

            Section("Оформление") {
                Picker("Тема", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Picker("Язык", selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Безопасность") {
                Toggle("Вход по Face ID", isOn: faceIDBinding)
                    .disabled(isUpdatingFaceID)
            }

            Section("iCloud") {
                iCloudStatus
            }

            Section("О приложении") {
                Text("Yet Another Habit помогает формировать полезные привычки и отслеживать прогресс.")
                    .foregroundStyle(.secondary)

                LabeledContent("Версия", value: appVersion)
            }
        }
        .contentMargins(.top, 12, for: .scrollContent)
        .listSectionSpacing(12)
        .onChange(of: selectedPhoto) {
            loadSelectedPhoto()
        }
        .onChange(of: isNameFocused) { wasFocused, isFocused in
            if wasFocused, !isFocused {
                saveNameIfNeeded()
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraPicker { image in
                prepareAvatar(image)
            }
            .ignoresSafeArea()
        }
        .onDisappear {
            avatarTask?.cancel()
            saveNameIfNeeded()
        }
        .saveErrorAlert($errorMessage)
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

        guard appLock.verifyFaceIDAvailability() else {
            faceIDEnabled = false
            errorMessage = appLock.errorMessage
            return
        }

        if await appLock.authenticate() {
            faceIDEnabled = true
        } else {
            faceIDEnabled = false
            errorMessage = appLock.errorMessage
        }
    }

    @ViewBuilder
    private var iCloudStatus: some View {
        switch cloudSyncStatus.state {
        case .checking:
            Label("Проверка iCloud…", systemImage: "icloud")
        case .available:
            Label("Синхронизация включена", systemImage: "icloud.fill")
                .foregroundStyle(.primary, .blue)
        case .noAccount:
            Label("Войдите в iCloud для синхронизации", systemImage: "person.crop.circle.badge.exclamationmark")
        case .restricted:
            Label("iCloud ограничен на этом устройстве", systemImage: "lock.icloud")
        case .unavailable:
            Label("iCloud временно недоступен", systemImage: "icloud.slash")
        case .localOnly:
            Label("На Simulator используется локальное хранилище", systemImage: "externaldrive.fill")
        }

        if cloudSyncStatus.state == .available {
            Text("Профиль, привычки и прогресс синхронизируются автоматически между вашими устройствами.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var avatarMenu: some View {
        Menu {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Выбрать из медиатеки", systemImage: "photo.on.rectangle")
            }

            Button {
                isCameraPresented = true
            } label: {
                Label("Сделать селфи", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            if profile.avatarData != nil {
                Divider()

                Button("Удалить фото", systemImage: "trash", role: .destructive) {
                    profile.avatarData = nil
                    saveProfile()
                }
            }
        } label: {
            avatar
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.blue, in: Circle())
                        .overlay {
                            Circle().stroke(.background, lineWidth: 2)
                        }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Изменить фото профиля")
    }

    @ViewBuilder
    private var avatar: some View {
        if
            let data = profile.avatarData,
            let image = UIImage(data: data)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 96, height: 96)
        }
    }

    private func loadSelectedPhoto() {
        guard let selectedPhoto else { return }

        avatarTask?.cancel()
        avatarTask = Task {
            do {
                guard
                    let data = try await selectedPhoto.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    return
                }

                guard !Task.isCancelled else { return }
                await resizeAndSaveAvatar(image)
                self.selectedPhoto = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }
        }
    }

    private func prepareAvatar(_ image: UIImage) {
        avatarTask?.cancel()
        avatarTask = Task {
            await resizeAndSaveAvatar(image)
        }
    }

    private func resizeAndSaveAvatar(_ image: UIImage) async {
        let targetSize = CGSize(width: 512, height: 512)
        let resizedImage = await image.byPreparingThumbnail(ofSize: targetSize) ?? image
        guard !Task.isCancelled else { return }
        profile.avatarData = resizedImage.jpegData(compressionQuality: 0.8)
        saveProfile()
    }

    private func saveNameIfNeeded() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name != profile.name else { return }
        profile.name = name
        saveProfile()
    }

    private func saveProfile() {
        profile.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            draftName = profile.name
            errorMessage = error.localizedDescription
        }
    }
}
