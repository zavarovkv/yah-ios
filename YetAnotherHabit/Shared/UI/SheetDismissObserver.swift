import SwiftUI
import UIKit

struct SheetDismissObserver: UIViewControllerRepresentable {
    let onWillDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onWillDismiss: onWillDismiss)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        context.coordinator.onWillDismiss = onWillDismiss

        DispatchQueue.main.async {
            viewController.parent?.presentationController?.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var onWillDismiss: () -> Void

        init(onWillDismiss: @escaping () -> Void) {
            self.onWillDismiss = onWillDismiss
        }

        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            onWillDismiss()
        }
    }
}
