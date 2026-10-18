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
    static let sidebar = TWStyle.classes(
        "px-2 py-2 w-full font-medium hover:bg-accent pressed:bg-border focus:border-ring " +
        "animate-smooth duration-120 motion-reduce:animate-none"
    )
    static let selection = TWStyle(
        .bg(.accent), .border(.border), .hover(.bg(.border)),
        .pressed(.bg(.primary), .fg(.onPrimary)),
        .classes("animate-smooth duration-120 motion-reduce:animate-none")
    )
}
