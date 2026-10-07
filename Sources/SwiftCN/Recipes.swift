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
                       .focus(.border(.primary)), .classes("control-motion"), .disabled(.opacity(0.45))),
         "toggle": Self(.text(.sm), .disabled(.opacity(0.45))),
         "label": Self(.text(.sm))]
        let components: [String: TWClasses] = [
            "button-ghost": "px-4 py-2 text-sm font-semibold rounded-md hover:bg-accent pressed:opacity-80 disabled:opacity-45",
            "button-link": "text-sm font-medium text-primary hover:opacity-80 disabled:opacity-45",
            "button-group": "bg-surface rounded-md",
            "control-motion": "animate-smooth duration-150",
            "disclosure-motion": "animate-spring duration-250",
            "feedback-motion": "animate-smooth duration-200",
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
            "empty": "p-8 w-full text-center text-mutedForeground rounded-lg border",
            "empty-title": "text-lg font-semibold text-foreground",
            "empty-description": "text-sm text-mutedForeground",
            "kbd": "cn-mono px-2 py-1 text-xs bg-accent text-mutedForeground border rounded-sm",
            "marker": "py-2 text-xs text-mutedForeground",
            "typography": "text-base text-foreground",
            "separator": "bg-border",
            "spinner": "w-5 h-5 text-primary",
            "spinner-motion": "cn-spin-[0.9]",
            "progress": "cn-tint-[primary]",
            "slider": "cn-tint-[primary]",
            "checkbox": "w-full text-sm cn-tint-[primary] disabled:opacity-45",
            "switch": "text-sm cn-tint-[primary] disabled:opacity-45",
            "radio-group": "text-sm cn-tint-[primary]",
            "select": "text-sm cn-tint-[primary]",
            "date-picker": "cn-tint-[primary]",
            "calendar": "p-3 bg-surface text-foreground border rounded-lg",
            "calendar-heading": "text-sm font-semibold",
            "calendar-weekday": "text-xs text-mutedForeground",
            "calendar-day": "px-0 py-0 text-sm font-medium rounded-md hover:bg-accent focus:bg-accent pressed:opacity-80 disabled:opacity-35 control-motion",
            "calendar-selected": "bg-primary text-onPrimary hover:bg-primary focus:bg-primary",
            "calendar-today": "border border-primary",
            "calendar-outside": "text-mutedForeground",
            "dropdown-content": "p-1 w-[240] bg-surface text-foreground rounded-lg border shadow-md",
            "dropdown-item": "px-2 py-2 text-sm rounded-md hover:bg-accent focus:bg-accent pressed:opacity-80 disabled:opacity-40 animate-none",
            "dropdown-label": "px-2 py-2 text-sm font-semibold",
            "textarea": "p-3 bg-background border rounded-md focus:border-primary disabled:opacity-45 control-motion",
            "input-group": "px-3 py-2 bg-background border rounded-md",
            "input-otp": "cn-mono text-xl",
            "accordion": "text-foreground",
            "accordion-item": "py-3",
            "collapsible": "text-foreground",
            "menu": "text-sm text-foreground",
            "dialog": "p-6 min-w-[320] max-w-[480] bg-surface text-foreground rounded-lg",
            "dialog-title": "text-lg font-semibold",
            "dialog-description": "text-sm text-mutedForeground",
            "dialog-footer": "pt-4",
            "presentation-dialog": "p-6 bg-surface text-foreground rounded-xl border shadow-md",
            "presentation-sheet": "p-6 bg-surface text-foreground border shadow-md",
            "drawer": "p-6 bg-surface text-foreground",
            "presentation-scrim": "bg-[#000000] opacity-35",
            "presentation-motion": "animate-spring duration-300",
            "popover": "p-4 bg-surface text-foreground rounded-lg border shadow-md",
            "popover-motion": "animate-smooth duration-150",
            "command": "bg-surface rounded-lg",
            "command-search": "px-4 py-1 min-h-[48] bg-surface border-0 focus:border-0 rounded-none",
            "command-item": "px-3 py-2 min-h-[36] text-sm rounded-md pressed:opacity-80 disabled:opacity-45",
            "combobox": "px-3 py-2 bg-background border rounded-md",
            "pagination": "text-sm",
            "scroll-area": "text-foreground",
            "skeleton": "bg-accent rounded-md",
            "skeleton-motion": "cn-shimmer-[1.6]",
            "toast": "p-4 bg-surface text-foreground border rounded-lg shadow-md",
            "table": "bg-surface text-foreground rounded-lg border w-full",
            "data-table": "bg-surface rounded-lg border w-full",
            "table-row": "hover:bg-accent animate-none",
            "table-row-selected": "bg-accent",
            "table-cell": "px-4 py-3 text-sm",
            "table-header": "px-4 py-3 text-xs font-medium text-mutedForeground bg-accent",
            "table-caption": "pt-2 text-xs text-mutedForeground",
            "tabs": "cn-tint-[primary]",
            "sidebar": "bg-surface text-foreground",
            "sidebar-list": "bg-surface",
            "sidebar-item-label": "text-sm font-medium",
            "sidebar-motion": "animate-smooth duration-250",
            "sidebar-scrim": "bg-[#000000] opacity-35",
            "sidebar-header": "p-2 w-full",
            "sidebar-content": "p-2 w-full",
            "sidebar-footer": "p-2 w-full",
            "sidebar-group": "w-full",
            "sidebar-group-label": "px-2 py-2 text-xs font-medium text-mutedForeground",
            "sidebar-menu": "w-full",
            "sidebar-menu-button": "px-2 py-2 w-full font-medium hover:bg-accent focus:bg-accent animate-none",
            "sidebar-menu-selected": "bg-accent text-onAccent hover:bg-accent",
            "sidebar-menu-badge": "px-2 py-1 text-xs bg-background text-mutedForeground rounded-sm",
            "sidebar-menu-sub": "pl-4 w-full",
            "sidebar-trigger": "text-mutedForeground hover:text-foreground",
            "carousel": "text-foreground",
            "chart": "p-4 bg-surface rounded-lg border cn-tint-[primary]",
            "questionnaire": "p-6 bg-surface rounded-lg border",
            "resizable": "text-foreground",
            "resizable-handle": "text-border hover:text-primary control-motion",
            "tooltip": "text-xs",
            "hover-card": "p-4 bg-surface text-foreground border shadow-md rounded-lg",
            "toggle-selected": "bg-primary text-onPrimary",
            "toggle-unselected": "bg-surface text-foreground border"
        ]
        for (name, classes) in components { recipes[name] = .classes(classes) }
        recipes["button-ghost"] = Self(buttonBase, .fg(.foreground), .hover(.bg(.accent)))
        recipes["button-link"] = Self(buttonBase, .px(0), .fg(.primary), .hover(.opacity(0.80)))
        recipes["input-group"] = Self(.px(3), .minH(inputMinimumHeight), .bg(.background), .border(.border), .rounded(.md), .focus(.border(.primary)), .disabled(.opacity(0.45)), .classes("control-motion"))
        recipes["input-group-field"] = Self(.text(.sm), .py(2), .minH(inputMinimumHeight))
        #if os(iOS)
        if let classes = components["checkbox"] { recipes["checkbox"] = Self(.classes(classes), .minW(44), .minH(44)) }
        for name in ["switch", "command-item", "sidebar-menu-button"] {
            if let classes = components[name] { recipes[name] = Self(.classes(classes), .minH(44)) }
        }
        #else
        for name in ["checkbox", "switch"] {
            if let classes = components[name] { recipes[name] = Self(.classes(classes), .minH(32)) }
        }
        #endif
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
                    .pressed(.opacity(0.80)), .classes("control-motion"), .disabled(.opacity(0.45)))
    }
}
