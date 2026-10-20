import SwiftUI
import SwiftCN

extension View {
    /// The gallery's chrome uses editable SwiftCN recipes. Preview controls keep their original recipes.
    @ViewBuilder func galleryChrome() -> some View {
        #if os(macOS)
        twRules(overrides: GalleryInteractionStyle.overrides).controlSize(.small)
        #else
        self
        #endif
    }
}

enum GalleryInteractionStyle {
    // Core recipes own interaction feedback. These are the gallery's visual differences.
    static let overrides = TWRuleOverrides(named: [
        "button-ghost": TWStyle(.weight(.semibold), .pressed(.bg(.border)), .disabled(.opacity(0.4))),
        "sidebar-menu-button": "focus:border-ring",
        "sidebar-menu-selected": TWStyle(.fg(.foreground), .border(.border))
    ])
    static let rules = overrides.applying(to: TWGlobalRules())
}
