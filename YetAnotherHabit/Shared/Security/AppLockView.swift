import SwiftUI

struct AppLockView: View {
    @Environment(AppLockController.self) private var appLock
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.system(size: 52))
                .foregroundStyle(.tint)

            Text("Приложение заблокировано")
                .font(.headline)

            if let errorMessage = appLock.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await appLock.authenticate(locale: locale) }
            } label: {
                if appLock.isAuthenticating {
                    ProgressView()
                } else {
                    Text("Разблокировать")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appLock.isAuthenticating)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
