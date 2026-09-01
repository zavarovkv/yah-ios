import Observation
import SwiftUI
import UIKit

enum AppTabBarIndicatorMode: Equatable {
    case count
    case dot
}

@MainActor
@Observable
final class AppTabBarPresentationState {
    private(set) var indicatorMode = AppTabBarIndicatorMode.count
    private(set) var forcesExpanded = false
    @ObservationIgnored private var observationRequest: (() -> Void)?
    @ObservationIgnored private var lastScrollDirectionWasDown: Bool?

    /// Uses hysteresis so reversing an interactive transition cannot rapidly
    /// alternate between the two pieces of artwork around its midpoint.
    func update(compactness: CGFloat) {
        let compactness = min(max(compactness, 0), 1)

        // Give control back to the native scroll policy before the next
        // gesture, once the forced transition is visibly near its expanded
        // endpoint. The indicator remains driven by the rendered titles.
        if forcesExpanded, compactness <= 0.20 {
            forcesExpanded = false
        }

        switch indicatorMode {
        case .count where compactness >= 0.64:
            indicatorMode = .dot
        case .dot where compactness <= 0.36:
            indicatorMode = .count
        default:
            break
        }
    }

    func reportScrollDirection(isScrollingDown: Bool) {
        guard lastScrollDirectionWasDown != isScrollingDown else { return }

        lastScrollDirectionWasDown = isScrollingDown
        forcesExpanded = !isScrollingDown
        observationRequest?()
    }

    func finishScrollInteraction() {
        lastScrollDirectionWasDown = nil
        forcesExpanded = false
    }

    func setObservationRequest(_ request: (() -> Void)?) {
        observationRequest = request
    }
}

/// Resolves the native transition from the actual visibility of the tab-item
/// titles. UIKit fades those titles while morphing the full tab bar into its
/// compact form. Unlike scroll direction or a fixed duration, this signal is
/// tied to what is currently rendered on screen.
struct AppTabBarTitleVisibilityResolver {
    private var expandedVisibility: CGFloat = 0

    mutating func compactness(titleVisibility: CGFloat) -> CGFloat {
        let titleVisibility = max(titleVisibility, 0)
        expandedVisibility = max(expandedVisibility, titleVisibility)

        guard expandedVisibility > 0.01 else { return 0 }
        return min(max(1 - titleVisibility / expandedVisibility, 0), 1)
    }
}

@available(iOS 26.0, *)
struct AppTabBarLayoutObserver: UIViewRepresentable {
    let presentationState: AppTabBarPresentationState

    func makeUIView(context: Context) -> AppTabBarObservationAttachmentView {
        AppTabBarObservationAttachmentView(
            presentationState: presentationState
        )
    }

    func updateUIView(
        _ view: AppTabBarObservationAttachmentView,
        context: Context
    ) {
        view.update(presentationState: presentationState)
        view.attachIfPossible()
    }

    static func dismantleUIView(
        _ view: AppTabBarObservationAttachmentView,
        coordinator: Void
    ) {
        view.disconnect()
    }
}

@available(iOS 26.0, *)
final class AppTabBarObservationAttachmentView: UIView {
    private weak var presentationState: AppTabBarPresentationState?
    private weak var observedController: UITabBarController?
    private var visibilityResolver = AppTabBarTitleVisibilityResolver()
    private var displayLink: CADisplayLink?
    private var displayLinkTarget: AppTabBarDisplayLinkTarget?
    private var lastTitleVisibility: CGFloat?
    private var stableFrameCount = 0

    init(presentationState: AppTabBarPresentationState) {
        self.presentationState = presentationState
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            disconnect()
        } else {
            attachIfPossible()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        attachIfPossible()
    }

    func update(presentationState: AppTabBarPresentationState) {
        guard self.presentationState !== presentationState else { return }
        self.presentationState?.setObservationRequest(nil)
        self.presentationState = presentationState
        installObservationRequest()
    }

    func attachIfPossible() {
        guard let window,
              let tabBarController = findTabBarController(in: window) else {
            return
        }

        guard observedController !== tabBarController else {
            installObservationRequest()
            return
        }

        observedController = tabBarController
        visibilityResolver = AppTabBarTitleVisibilityResolver()
        lastTitleVisibility = nil
        stableFrameCount = 0
        presentationState?.update(compactness: 0)
        installObservationRequest()
        startMonitoring()
    }

    func disconnect() {
        presentationState?.setObservationRequest(nil)
        displayLink?.invalidate()
        displayLink = nil
        displayLinkTarget = nil
        observedController = nil
        lastTitleVisibility = nil
        stableFrameCount = 0
    }

    private func installObservationRequest() {
        presentationState?.setObservationRequest { [weak self] in
            self?.startMonitoring()
        }
    }

    private func startMonitoring() {
        guard observedController != nil else { return }

        if displayLink == nil {
            let target = AppTabBarDisplayLinkTarget(owner: self)
            let displayLink = CADisplayLink(
                target: target,
                selector: #selector(AppTabBarDisplayLinkTarget.tick)
            )
            displayLink.add(to: .main, forMode: .common)
            displayLink.isPaused = true
            displayLinkTarget = target
            self.displayLink = displayLink
        }

        if displayLink?.isPaused == true {
            stableFrameCount = 0
            lastTitleVisibility = nil
            displayLink?.isPaused = false
        }
    }

    fileprivate func sampleTabBar() {
        guard let observedController else {
            displayLink?.isPaused = true
            return
        }

        let titleVisibility = visibleTitleOpacity(
            in: observedController.tabBar
        )
        let compactness = visibilityResolver.compactness(
            titleVisibility: titleVisibility
        )
        presentationState?.update(compactness: compactness)

        if let lastTitleVisibility,
           abs(lastTitleVisibility - titleVisibility) < 0.005,
           !tabBarHasActiveAnimations(observedController.tabBar) {
            stableFrameCount += 1
        } else {
            stableFrameCount = 0
        }
        self.lastTitleVisibility = titleVisibility

        if stableFrameCount >= 4 {
            displayLink?.isPaused = true
        }
    }

    private func visibleTitleOpacity(in tabBar: UITabBar) -> CGFloat {
        let titles = Set(tabBar.items?.compactMap(\.title) ?? [])
        guard !titles.isEmpty else { return 0 }

        return descendants(of: tabBar)
            .compactMap { $0 as? UILabel }
            .filter { label in
                guard let text = label.text else { return false }
                return titles.contains(text)
            }
            .reduce(0) { result, label in
                result + effectivePresentationOpacity(
                    of: label,
                    relativeTo: tabBar
                )
            }
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { child in
            [child] + descendants(of: child)
        }
    }

    private func effectivePresentationOpacity(
        of view: UIView,
        relativeTo ancestor: UIView
    ) -> CGFloat {
        var opacity: Float = 1
        var current: UIView? = view

        while let candidate = current, candidate !== ancestor {
            if candidate.isHidden {
                return 0
            }
            opacity *= candidate.layer.presentation()?.opacity
                ?? candidate.layer.opacity
            current = candidate.superview
        }

        return CGFloat(opacity)
    }

    private func tabBarHasActiveAnimations(_ tabBar: UITabBar) -> Bool {
        descendants(of: tabBar).contains { view in
            !(view.layer.animationKeys()?.isEmpty ?? true)
        }
    }

    private func findTabBarController(
        in window: UIWindow
    ) -> UITabBarController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UITabBarController {
                return controller
            }
            if let controller = current as? UIViewController,
               let tabBarController = controller.tabBarController {
                return tabBarController
            }
            responder = current.next
        }

        guard let rootViewController = window.rootViewController else {
            return nil
        }
        return findTabBarController(
            in: rootViewController,
            matching: window
        )
    }

    private func findTabBarController(
        in controller: UIViewController,
        matching window: UIWindow
    ) -> UITabBarController? {
        if let tabBarController = controller as? UITabBarController,
           tabBarController.viewIfLoaded?.window === window {
            return tabBarController
        }

        if let presented = controller.presentedViewController,
           let match = findTabBarController(in: presented, matching: window) {
            return match
        }

        for child in controller.children.reversed() {
            if let match = findTabBarController(in: child, matching: window) {
                return match
            }
        }

        return nil
    }
}

@available(iOS 26.0, *)
private final class AppTabBarDisplayLinkTarget: NSObject {
    weak var owner: AppTabBarObservationAttachmentView?

    init(owner: AppTabBarObservationAttachmentView) {
        self.owner = owner
    }

    @objc func tick() {
        owner?.sampleTabBar()
    }
}
