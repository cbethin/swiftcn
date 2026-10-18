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
    // A stable revision keeps the shared class-expansion cache warm across updates.
    static let overrides = TWRuleOverrides(named: [
        "button-ghost": button, "sidebar-menu-button": sidebar, "sidebar-menu-selected": selection
    ])

    static let rules = overrides.applying(to: TWGlobalRules())

    // A native Button still owns activation, keyboard focus, cancellation, and disabled behavior.
    // A plain SwiftCN surface lets hover and press decorate the complete hit area on macOS.
    static let button = TWStyle(
        .weight(.semibold),
        .hover(.bg(.accent)), .pressed(.bg(.border), .opacity(0.8)),
        .focus(.border(.ring, width: 2)), .disabled(.opacity(0.4)),
        .classes("animate-none")
    )
    // Navigation rows should track the pointer quietly, without trailing fades or a press flash.
    // An explicit base fill also avoids interpolating from a transparent surface.
    static let sidebar = TWStyle(
        .bg(.muted), .hover(.bg(.accent)), .pressed(.bg(.accent), .opacity(1)),
        .classes("focus:border-ring animate-none")
    )
    static let selection = TWStyle(
        .bg(.accent), .fg(.foreground), .border(.border),
        .hover(.bg(.accent)), .pressed(.bg(.accent)),
        .classes("animate-none")
    )
}
