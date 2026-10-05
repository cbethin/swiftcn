import SwiftUI
import SwiftCN

/// The live motion sample, shared with the native geometry regression test.
struct MotionSurface: View {
    let expanded: Bool
    let motionClasses: String
    let animationScope: TWAnimationScope
    private var motion = DemoMotion()

    init(expanded: Bool, motionClasses: String, animationScope: TWAnimationScope = .all) {
        self.expanded = expanded
        self.motionClasses = motionClasses
        self.animationScope = animationScope
    }

    static func classes(expanded: Bool, motion: String) -> String {
        "\(expanded ? "p-8 rounded-xl bg-primary text-primary-foreground" : "p-3 rounded-md bg-accent text-foreground") \(motion)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .symbolEffect(.bounce, options: .speed(1.4), value: expanded)
                .symbolEffectsRemoved(!motion.isEnabled || motionClasses.split(separator: " ").contains("animate-none"))
                .accessibilityHidden(true)
            Text("Hello, SwiftUI")
                // Keep the label's ink fixed while its foreground and surrounding layout change.
                .contentTransition(.identity)
        }
        .tw(Self.classes(expanded: expanded, motion: motionClasses), value: expanded, animationScope: animationScope)
    }
}
