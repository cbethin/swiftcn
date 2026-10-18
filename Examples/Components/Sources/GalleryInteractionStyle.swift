import SwiftUI
import SwiftCN

extension View {
    /// The gallery's chrome uses editable SwiftCN recipes. Preview controls keep their original recipes.
    @ViewBuilder func galleryChrome() -> some View {
        #if os(macOS)
        twRules { rules in
            rules.named["button-ghost"] = GalleryInteractionStyle.button
            rules.named["sidebar-menu-button"] = GalleryInteractionStyle.sidebar
            rules.named["sidebar-menu-selected"] = GalleryInteractionStyle.selection
        }
        #else
        self
        #endif
    }
}

private enum GalleryInteractionStyle {
    // A native Button still owns activation, keyboard focus, cancellation, and disabled behavior.
    // A plain SwiftCN surface lets hover and press decorate the complete hit area on macOS.
    static let button = TWStyle(
        .px(3), .rounded(.md), .text(.sm), .weight(.semibold), .fg(.foreground), .minH(32),
        .hover(.bg(.accent)), .pressed(.bg(.border), .opacity(0.8)),
        .focus(.border(.ring, width: 2)), .disabled(.opacity(0.4)),
        .classes("animate-smooth duration-120 motion-reduce:animate-none")
    )
    // Navigation rows should track the pointer quietly, without trailing fades or a press flash.
    // An explicit base fill also avoids interpolating from a transparent surface.
    static let sidebar = TWStyle(
        .bg(.muted), .hover(.bg(.accent)), .pressed(.bg(.accent), .opacity(1)),
        .classes("px-2 py-2 w-full font-medium focus:border-ring animate-none")
    )
    static let selection = TWStyle(
        .bg(.accent), .fg(.foreground), .border(.border),
        .hover(.bg(.accent)), .pressed(.bg(.accent)),
        .classes("animate-none")
    )
}
