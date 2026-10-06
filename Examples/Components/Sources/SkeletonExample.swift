import SwiftUI
import SwiftCN

struct SkeletonExample: View {
    @State private var isLoading = true
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            CNAdaptiveActionLayout(spacing: 16) {
                CNSkeleton(isLoading: isLoading, classes: "rounded-full") {
                    CNAvatar(accessibilityLabel: "Charles Bethin", classes: "w-12 h-12") { Text("CB").lineLimit(1).minimumScaleFactor(0.5) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    CNSkeleton(isLoading: isLoading) { Text("Your next great project").tw("font-semibold") }
                    CNSkeleton(isLoading: isLoading) {
                        Text("A fresh canvas for your team.").tw("text-sm text-mutedForeground")
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).tw("p-4 border rounded-lg w-full")
            CNButton(isLoading ? "Reveal content" : "Show skeleton", variant: .outline) { isLoading.toggle() }
        }
    }
}
