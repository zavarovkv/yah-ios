import SwiftUI

struct DailySuccessBannerView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let snapshot: HabitDailySuccessPolicy.Snapshot

    @State private var isCelebrating = false
    @State private var showsSparkles = false

    var body: some View {
        HStack(spacing: 14) {
            achievementSymbol

            VStack(alignment: .leading, spacing: 3) {
                Text("Все цели достигнуты")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(
                    "\(snapshot.completedCount) из \(snapshot.goalCount) · Отличная работа!"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.yellow)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(showsSparkles ? 1 : 0.6)
                .opacity(showsSparkles ? 1 : 0)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

            shape
                .fill(.thinMaterial)
                .overlay {
                    shape.fill(Color.green.opacity(0.1))
                }
                .overlay {
                    shape.strokeBorder(Color.green.opacity(0.24), lineWidth: 1)
                }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .task {
            await celebrateAppearance()
        }
    }

    private var achievementSymbol: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.14))

            Circle()
                .strokeBorder(Color.green.opacity(0.28), lineWidth: 1)
                .scaleEffect(isCelebrating ? 1.5 : 0.82)
                .opacity(isCelebrating ? 0 : 0.7)

            Image(systemName: "checkmark.seal.fill")
                .font(.title2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
                .symbolEffect(
                    .bounce,
                    options: .nonRepeating,
                    value: accessibilityReduceMotion ? false : isCelebrating
                )
        }
        .frame(width: 46, height: 46)
        .accessibilityHidden(true)
    }

    @MainActor
    private func celebrateAppearance() async {
        guard !accessibilityReduceMotion else {
            isCelebrating = true
            return
        }

        await Task.yield()
        guard !Task.isCancelled else { return }

        withAnimation(.smooth(duration: 0.42)) {
            isCelebrating = true
            showsSparkles = true
        }

        do {
            try await Task.sleep(for: .milliseconds(650))
            withAnimation(.easeOut(duration: 0.22)) {
                showsSparkles = false
            }
        } catch {
            // The view disappeared before its one-shot celebration completed.
        }
    }
}
