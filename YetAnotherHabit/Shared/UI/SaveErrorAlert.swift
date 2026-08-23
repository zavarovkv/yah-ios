import SwiftUI

extension View {
    func appErrorAlert(
        _ title: LocalizedStringKey,
        error: Binding<String?>
    ) -> some View {
        alert(title, isPresented: error.isPresent) {
            Button("ОК", role: .cancel) {}
        } message: {
            if let message = error.wrappedValue {
                Text(message)
            } else {
                Text("Попробуйте ещё раз.")
            }
        }
    }

    func saveErrorAlert(_ error: Binding<String?>) -> some View {
        appErrorAlert("Не удалось сохранить изменения", error: error)
    }
}

private extension Binding where Value == String? {
    var isPresent: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}
