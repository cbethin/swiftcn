import SwiftUI
import SwiftCN

public enum CNButtonVariant: String, CaseIterable, Sendable {
    case primary, secondary, outline, destructive, ghost, link
    public var classes: TWClasses { TWClasses("button-\(rawValue)") }
}
public enum CNButtonSize: Sendable {
    case regular, small, large, icon
    public var classes: TWClasses {
        switch self {
        case .regular: ""
        case .small: "control-sm"
        case .large: "control-lg"
        case .icon: "rounded-full"
        }
    }
}

/// Native Button: roles, keyboard shortcuts, disabled state and activation stay with SwiftUI.
public struct CNButton<Label: View>: View {
    private let role: ButtonRole?
    private let variant: CNButtonVariant
    private let size: CNButtonSize
    private let classes: TWClasses
    private let action: () -> Void
    private let label: Label
    @FocusState private var isFocused: Bool

    public init(role: ButtonRole? = nil, variant: CNButtonVariant = .primary, size: CNButtonSize = .regular,
                classes: TWClasses = "", action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role; self.variant = variant; self.size = size; self.classes = classes
        self.action = action; self.label = label()
    }
    public init(_ title: LocalizedStringKey, role: ButtonRole? = nil, variant: CNButtonVariant = .primary,
                size: CNButtonSize = .regular, classes: TWClasses = "", action: @escaping () -> Void) where Label == Text {
        self.init(role: role, variant: variant, size: size, classes: classes, action: action) { Text(title) }
    }
    public var body: some View {
        Button(role: role, action: action) { label }
            .focused($isFocused)
            .buttonStyle(.tw(cn(variant.classes, size.classes, classes), state: .init(isFocused: isFocused)))
    }
}

public struct CNButtonGroup<Content: View>: View {
    private let axis: Axis
    private let classes: TWClasses
    private let content: Content
    public init(axis: Axis = .horizontal, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.axis = axis; self.classes = classes; self.content = content()
    }
    public var body: some View {
        let layout = axis == .horizontal ? AnyLayout(CNAdaptiveActionLayout(spacing: 4)) : AnyLayout(VStackLayout(spacing: 4))
        layout { content }.tw(cn("button-group", classes))
    }
}
