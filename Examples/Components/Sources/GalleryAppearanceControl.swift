import SwiftUI
import SwiftCN

struct GalleryAppearanceControl: View {
    @Binding var dark: Bool

    var body: some View {
        CNSegmentedControl(selection: $dark, classes: "p-[3] rounded-full border", animated: true) {
            CNSegment(false, classes: "control-icon rounded-full") {
                Image(systemName: "sun.max.fill").font(.system(size: 13, weight: .semibold))
            }
            .accessibilityLabel("Use light appearance").help("Light appearance")
            CNSegment(true, classes: "control-icon rounded-full") {
                Image(systemName: "moon.fill").font(.system(size: 13, weight: .semibold))
            }
            .accessibilityLabel("Use dark appearance").help("Dark appearance")
        }
        .controlSize(.small)
        .accessibilityLabel("Appearance")
        .twRules(overrides: Self.appearance)
    }

    private static let appearance = TWRuleOverrides(named: [
        "segmented-item": "selected:text-onPrimary selected:hover:text-onPrimary",
        "segmented-indicator": "bg-primary border-0 shadow-none rounded-full"
    ])
}
