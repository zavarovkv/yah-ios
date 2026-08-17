import SwiftUI

struct AppLockView: View {
    @Environment(AppLockController.self) private var appLock

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

            Button("Разблокировать") {
                Task { await appLock.authenticate() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appLock.isAuthenticating)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
