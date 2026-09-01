import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ProfileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Bindable var profile: UserProfile

    @State private var draftName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPresented = false
    @State private var errorMessage: String?
    @State private var avatarTask: Task<Void, Never>?
    @State private var avatarTaskID: UUID?
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
        }
        .contentMargins(.top, 12, for: .scrollContent)
        .listSectionSpacing(12)
        .onChange(of: selectedPhoto) {
            loadSelectedPhoto()
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhoto,
            matching: .images,
            preferredItemEncoding: .automatic
        )
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
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .appErrorAlert("Не удалось обновить профиль", error: $errorMessage)
    }

    private var avatarMenu: some View {
        Menu {
            Button {
                isPhotoPickerPresented = true
            } label: {
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
            ProfileAvatarView(data: profile.avatarData, size: 96)
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

    private func loadSelectedPhoto() {
        guard let selectedPhoto else { return }

        avatarTask?.cancel()
        let taskID = UUID()
        avatarTaskID = taskID
        avatarTask = Task {
            defer { finishAvatarTask(taskID) }
            do {
                guard
                    let data = try await selectedPhoto.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    errorMessage = AppLocalization.string(
                        "Не удалось загрузить выбранное фото.",
                        locale: locale
                    )
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
        let taskID = UUID()
        avatarTaskID = taskID
        avatarTask = Task {
            defer { finishAvatarTask(taskID) }
            await resizeAndSaveAvatar(image)
        }
    }

    private func finishAvatarTask(_ taskID: UUID) {
        guard avatarTaskID == taskID else { return }
        avatarTask = nil
        avatarTaskID = nil
    }

    private func resizeAndSaveAvatar(_ image: UIImage) async {
        let targetSize = CGSize(width: 512, height: 512)
        let resizedImage = await image.byPreparingThumbnail(ofSize: targetSize) ?? image
        guard !Task.isCancelled else { return }
        guard let avatarData = resizedImage.jpegData(compressionQuality: 0.8) else {
            errorMessage = AppLocalization.string(
                "Не удалось обработать фото.",
                locale: locale
            )
            return
        }
        profile.avatarData = avatarData
        saveProfile()
    }

    private func saveNameIfNeeded() {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.isEmpty
            ? UserProfileReconciler.generatedName(locale: locale)
            : trimmedName
        draftName = name
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
