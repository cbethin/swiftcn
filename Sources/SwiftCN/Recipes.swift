import SwiftUI

/// Editable defaults. Native Button roles remain separate from appearance variants.
extension TWStyle {
    public static var card: Self {
        .classes("card")
    }

    public static var primaryButton: Self {
        .classes("button-primary")
    }

    public static var secondaryButton: Self {
        .classes("button-secondary")
    }

    public static var outlineButton: Self {
        .classes("button-outline")
    }

    public static var destructiveButton: Self {
        .classes("button-destructive")
    }

    /// Built-in classes stay editable when you copy these source files.
    static let defaultClasses: [String: Self] = {
        ["card": Self(.p(6), .bg(.surface), .fg(.foreground), .rounded(.lg), .border(.border), .shadow(.sm)),
         "button-primary": Self(buttonBase, .bg(.primary), .fg(.onPrimary), .hover(.opacity(0.92))),
         "button-secondary": Self(buttonBase, .bg(.accent), .fg(.onAccent), .hover(.opacity(0.85))),
         "button-outline": Self(buttonBase, .bg(.surface), .fg(.foreground), .border(.border), .hover(.bg(.accent))),
         "button-destructive": Self(buttonBase, .bg(.destructive), .fg(.onDestructive), .hover(.opacity(0.92))),
         "card-header": Self(.p(6), .pb(0)),
         "card-content": Self(.p(6)),
         "card-footer": Self(.p(6), .pt(0)),
         "card-title": Self(.text(.lg), .weight(.semibold)),
         "card-description": Self(.text(.sm), .fg(.mutedForeground)),
         "field": Self(), "field-group": Self(),
         "field-label": Self(.text(.sm), .weight(.medium)),
         "field-description": Self(.text(.xs), .fg(.mutedForeground)),
         "field-error": Self(.text(.xs), .fg(.destructive)),
         "field-invalid": Self(.border(.destructive), .focus(.border(.destructive))),
         "input": Self(.px(3), .py(2), .minH(inputMinimumHeight), .bg(.background), .border(.border), .rounded(.md),
                       .focus(.border(.primary)), .disabled(.opacity(0.45))),
         "toggle": Self(.text(.sm), .disabled(.opacity(0.45))),
         "label": Self(.text(.sm))]
    }()

    /// Read a built-in definition when extending that same class globally.
    public static func defaultStyle(for name: String) -> Self? { defaultClasses[name] }

    private static var inputMinimumHeight: CGFloat {
        #if os(iOS)
        44
        #else
        36
        #endif
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
