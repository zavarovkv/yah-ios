import SwiftData
import SwiftUI

private enum AppTab: Hashable {
    case habits
    case progress
    case profile
}

struct ContentView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @Environment(AppDataState.self) private var appDataState
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(filter: #Predicate<HabitCompletion> { $0.count > 0 })
    private var completions: [HabitCompletion]
    @AppStorage(AppPreferenceKey.dataMaintenanceVersion)
    private var dataMaintenanceVersion = 0
    @State private var maintenanceError: String?

    var body: some View {
        let persistedCompletionCounts = HabitCompletionIndex.counts(in: completions)
        let presentationData = appDataState.presentationData(
            persistedHabits: habits,
            persistedCompletionCounts: persistedCompletionCounts
        )

        AppTabView(data: presentationData, profiles: profiles)
            .task {
                let repairCompletions = dataMaintenanceVersion < DataMaintenance.currentVersion

                do {
                    try DataMaintenance.reconcile(
                        context: modelContext,
                        calendar: calendar,
                        locale: locale,
                        repairCompletions: repairCompletions
                    )
                    if repairCompletions {
                        dataMaintenanceVersion = DataMaintenance.currentVersion
                    }
                } catch {
                    maintenanceError = error.localizedDescription
                }
            }
            .onChange(of: habits.map(\.identifier)) {
                appDataState.reconcile(
                    habits: habits,
                    completionCounts: persistedCompletionCounts
                )
            }
            .onChange(of: persistedCompletionCounts) {
                appDataState.reconcile(
                    habits: habits,
                    completionCounts: persistedCompletionCounts
                )
            }
            .appErrorAlert("Не удалось подготовить данные", error: $maintenanceError)
    }
}

/// Owns transient tab selection so switching tabs does not invalidate the
/// parent view and rebuild the completion index for the entire history.
private struct AppTabView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let data: HabitPresentationData
    let profiles: [UserProfile]
    @State private var selectedTab = AppTab.habits
    @State private var tabBarPresentationState = AppTabBarPresentationState()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .habits) {
                HabitsView(
                    data: data,
                    onTabBarScrollDirectionChanged: handleTabBarScrollDirection,
                    onTabBarScrollInteractionEnded: handleTabBarScrollInteractionEnded
                )
            } label: {
                Label {
                    Text("Привычки")
                } icon: {
                    HabitTabIcon(
                        isSelected: selectedTab == .habits,
                        incompleteCount: incompleteHabitCount,
                        presentationState: tabBarPresentationState
                    )
                }
            }
            .badge(habitsBadge)

            Tab(value: .progress) {
                ProgressScreen(data: data)
            } label: {
                Label {
                    Text("Прогресс")
                } icon: {
                    animatedSymbol(
                        "chart.bar",
                        selectedSystemImage: "chart.bar.fill",
                        tab: .progress
                    )
                }
            }

            Tab(value: .profile) {
                SettingsView(profiles: profiles)
            } label: {
                Label {
                    Text("Вы")
                } icon: {
                    ProfileAvatarView(data: profiles.first?.avatarData, size: 24)
                        .scaleEffect(selectedTab == .profile ? 1.1 : 1)
                        .animation(tabAnimation, value: selectedTab)
                }
            }
        }
        .modifier(
            AdaptiveTabBarMaterial(
                forcesExpanded: tabBarPresentationState.forcesExpanded
            )
        )
        .background {
            if #available(iOS 26, *) {
                AppTabBarLayoutObserver(
                    presentationState: tabBarPresentationState
                )
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }
        }
    }

    private var incompleteHabitCount: Int {
        let today = calendar.startOfDay(for: .now)

        return HabitDaySorter.incompleteCount(
            in: data.habits,
            for: today,
            completionCounts: data.completionCounts,
            calendar: calendar
        )
    }

    private var habitsBadge: Text? {
        if #available(iOS 26, *) {
            return nil
        }

        guard incompleteHabitCount > 0 else {
            return nil
        }

        return Text(verbatim: String(incompleteHabitCount))
    }

    private func handleTabBarScrollDirection(_ isScrollingDown: Bool) {
        guard #available(iOS 26, *) else { return }
        withAnimation(tabBarPolicyAnimation) {
            tabBarPresentationState.reportScrollDirection(
                isScrollingDown: isScrollingDown
            )
        }
    }

    private func handleTabBarScrollInteractionEnded() {
        guard #available(iOS 26, *) else { return }
        withAnimation(tabBarPolicyAnimation) {
            tabBarPresentationState.finishScrollInteraction()
        }
    }

    private func animatedSymbol(
        _ systemImage: String,
        selectedSystemImage: String,
        tab: AppTab
    ) -> some View {
        Image(systemName: selectedTab == tab ? selectedSystemImage : systemImage)
            .scaleEffect(selectedTab == tab ? 1.1 : 1)
            .animation(tabAnimation, value: selectedTab)
    }

    private var tabAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .bouncy(duration: 0.25, extraBounce: 0.08)
    }

    private var tabBarPolicyAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .smooth(duration: 0.48)
    }
}

private struct HabitTabIcon: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let isSelected: Bool
    let incompleteCount: Int
    let presentationState: AppTabBarPresentationState

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                Image(
                    uiImage: HabitTabIconArtwork.image(
                        isSelected: isSelected,
                        indicator: indicator
                    )
                )
            } else {
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                )
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1)
        .animation(iconAnimation, value: isSelected)
    }

    private var iconAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .bouncy(duration: 0.25, extraBounce: 0.08)
    }

    private var indicator: HabitTabIconIndicator {
        guard incompleteCount > 0 else { return .none }

        switch presentationState.indicatorMode {
        case .count:
            let value = incompleteCount > 99
                ? "99+"
                : String(incompleteCount)
            return .count(value)
        case .dot:
            return .dot
        }
    }
}

private enum HabitTabIconIndicator {
    case none
    case dot
    case count(String)
}

private enum HabitTabIconArtwork {
    private static let symbolConfiguration = UIImage.SymbolConfiguration(
        pointSize: 23,
        weight: .regular
    )

    static func image(
        isSelected: Bool,
        indicator: HabitTabIconIndicator
    ) -> UIImage {
        let name = isSelected
            ? "checkmark.circle.fill"
            : "checkmark.circle"
        guard let symbol = UIImage(
            systemName: name,
            withConfiguration: symbolConfiguration
        ) else {
            return UIImage()
        }

        return image(
            symbol: symbol,
            isSelected: isSelected,
            indicator: indicator
        )
    }

    private static func image(
        symbol: UIImage,
        isSelected: Bool,
        indicator: HabitTabIconIndicator
    ) -> UIImage {
        let canvasSize = CGSize(width: 40, height: 30)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { _ in
            let symbolOrigin = CGPoint(
                x: 5,
                y: canvasSize.height - symbol.size.height - 1
            )
            symbol
                .withTintColor(
                    isSelected ? .systemBlue : .secondaryLabel,
                    renderingMode: .alwaysOriginal
                )
                .draw(at: symbolOrigin)

            switch indicator {
            case .none:
                break
            case .dot:
                drawDot()
            case .count(let value):
                drawCount(value, in: canvasSize)
            }
        }
        .withRenderingMode(.alwaysOriginal)
    }

    private static func drawDot() {
        UIColor.systemRed.setFill()
        UIBezierPath(
            ovalIn: CGRect(x: 27, y: 1, width: 7, height: 7)
        )
        .fill()
    }

    private static func drawCount(_ value: String, in canvasSize: CGSize) {
        let font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = (value as NSString).size(withAttributes: attributes)
        let badgeSize = CGSize(
            width: max(18, ceil(textSize.width) + 7),
            height: 17
        )
        let badgeRect = CGRect(
            x: canvasSize.width - badgeSize.width,
            y: 0,
            width: badgeSize.width,
            height: badgeSize.height
        )

        UIColor.systemRed.setFill()
        UIBezierPath(
            roundedRect: badgeRect,
            cornerRadius: badgeSize.height / 2
        )
        .fill()

        let textRect = CGRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (value as NSString).draw(in: textRect, withAttributes: attributes)
    }
}

private struct AdaptiveTabBarMaterial: ViewModifier {
    let forcesExpanded: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .tabBarMinimizeBehavior(
                    forcesExpanded ? .never : .onScrollDown
                )
        } else {
            content
                .toolbarBackground(.thinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppDataState())
        .environment(AppLockController())
        .modelContainer(
            for: [Habit.self, HabitCompletion.self, UserProfile.self],
            inMemory: true
        )
}
