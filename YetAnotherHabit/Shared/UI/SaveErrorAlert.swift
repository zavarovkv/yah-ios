import SwiftUI

extension View {
    func saveErrorAlert(_ error: Binding<String?>) -> some View {
        alert("Не удалось сохранить изменения", isPresented: error.isPresent) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text(error.wrappedValue ?? String(localized: "Попробуйте ещё раз."))
        }
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
