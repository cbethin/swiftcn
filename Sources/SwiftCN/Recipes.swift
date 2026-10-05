import SwiftUI

/// Editable defaults. Native Button roles remain separate from appearance variants.
extension TWStyle {
    public static var card: Self {
        Self(.p(6), .bg(.surface), .fg(.foreground), .rounded(.lg), .border(.border), .shadow(.sm))
    }

    public static var primaryButton: Self {
        Self(buttonBase, .bg(.primary), .fg(.onPrimary), .hover(.opacity(0.92)))
    }

    public static var secondaryButton: Self {
        Self(buttonBase, .bg(.accent), .fg(.onAccent), .hover(.opacity(0.85)))
    }

    public static var outlineButton: Self {
        Self(buttonBase, .bg(.surface), .fg(.foreground), .border(.border), .hover(.bg(.accent)))
    }

    public static var destructiveButton: Self {
        Self(buttonBase, .bg(.destructive), .fg(.onDestructive), .hover(.opacity(0.92)))
    }

    private static var buttonBase: Self {
        #if os(iOS)
        let minimumHeight: CGFloat = 44
        #else
        let minimumHeight: CGFloat = 32
        #endif
        return Self(.px(4), .py(2), .minH(minimumHeight), .text(.sm), .weight(.semibold), .rounded(.md),
                    .pressed(.opacity(0.80)), .disabled(.opacity(0.45)))
    }
}
