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
        var recipes: [String: Self] = ["card": Self(.p(6), .bg(.surface), .fg(.foreground), .rounded(.lg), .border(.border), .shadow(.sm)),
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
        let components: [String: TWClasses] = [
            "button-ghost": "px-4 py-2 text-sm font-semibold rounded-md hover:bg-accent pressed:opacity-80 disabled:opacity-45",
            "button-link": "text-sm font-medium text-primary hover:opacity-80 disabled:opacity-45",
            "button-group": "bg-surface rounded-md",
            "badge": "px-2 py-1 text-xs font-semibold bg-primary text-onPrimary rounded-full",
            "alert": "p-4 bg-surface text-foreground border rounded-lg",
            "alert-title": "text-sm font-semibold",
            "alert-description": "text-sm text-mutedForeground",
            "avatar": "cn-avatar-crop w-10 h-10 bg-accent text-onAccent rounded-full",
            "breadcrumb": "text-sm text-mutedForeground",
            "bubble": "px-4 py-3 bg-accent text-onAccent rounded-xl",
            "message": "py-2 text-foreground",
            "message-meta": "text-xs text-mutedForeground",
            "attachment": "p-3 bg-surface border rounded-lg",
            "item": "p-4 bg-surface border rounded-lg",
            "item-title": "text-sm font-medium",
            "item-description": "text-sm text-mutedForeground",
            "empty": "p-6 text-mutedForeground rounded-lg border",
            "empty-title": "text-lg font-semibold text-foreground",
            "empty-description": "text-sm text-mutedForeground",
            "kbd": "cn-mono px-2 py-1 text-xs bg-accent text-mutedForeground border rounded-sm",
            "marker": "py-2 text-xs text-mutedForeground",
            "typography": "text-base text-foreground",
            "separator": "bg-border",
            "spinner": "cn-tint-[primary]",
            "progress": "cn-tint-[primary]",
            "slider": "cn-tint-[primary]",
            "checkbox": "text-sm cn-tint-[primary] disabled:opacity-45",
            "switch": "text-sm cn-tint-[primary] disabled:opacity-45",
            "radio-group": "text-sm cn-tint-[primary]",
            "select": "text-sm cn-tint-[primary]",
            "calendar": "cn-tint-[primary]",
            "textarea": "p-3 bg-background border rounded-md",
            "input-group": "px-3 py-2 bg-background border rounded-md",
            "input-otp": "cn-mono text-xl",
            "accordion": "text-foreground",
            "accordion-item": "py-3",
            "collapsible": "text-foreground",
            "menu": "text-sm text-foreground",
            "dialog": "p-6 bg-surface text-foreground rounded-lg",
            "dialog-title": "text-lg font-semibold",
            "dialog-description": "text-sm text-mutedForeground",
            "dialog-footer": "pt-4",
            "popover": "p-4 bg-surface text-foreground rounded-lg",
            "command": "p-2 bg-surface rounded-lg",
            "command-item": "px-3 py-2 rounded-md",
            "combobox": "px-3 py-2 bg-background border rounded-md",
            "pagination": "text-sm",
            "scroll-area": "text-foreground",
            "skeleton": "bg-accent rounded-md",
            "toast": "p-4 bg-surface text-foreground border rounded-lg shadow-md",
            "table": "bg-surface text-foreground rounded-lg border",
            "table-cell": "px-3 py-2 text-sm",
            "table-header": "px-3 py-2 text-sm font-semibold bg-accent",
            "tabs": "cn-tint-[primary]",
            "sidebar": "text-foreground",
            "carousel": "text-foreground",
            "chart": "p-4 bg-surface rounded-lg border cn-tint-[primary]",
            "questionnaire": "p-6 bg-surface rounded-lg border",
            "resizable": "text-foreground",
            "resizable-handle": "text-border",
            "tooltip": "text-xs",
            "hover-card": "p-4 bg-surface rounded-lg",
            "toggle-selected": "bg-primary text-onPrimary",
            "toggle-unselected": "bg-surface text-foreground border"
        ]
        for (name, classes) in components { recipes[name] = .classes(classes) }
        return recipes
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
