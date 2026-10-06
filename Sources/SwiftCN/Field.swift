import SwiftUI

/// Group native controls and their descriptions without replacing their accessibility elements.
public struct CNField<Content: View>: View {
    private let isInvalid: Bool
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(isInvalid: Bool = false, classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.isInvalid = isInvalid
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("field", classes))
            .environment(\.twFieldInvalid, isInvalid)
    }
}

/// Group independent fields. Each CNField owns its own validation appearance.
public struct CNFieldGroup<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(_ classes: TWClasses = "", spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("field-group", classes))
    }
}

/// Decorate an arbitrary native control; its label, binding, and behavior remain native.
public struct CNFieldControl<Content: View>: View {
    private let style: TWStyle
    private let state: TWState
    private let content: Content

    public init(_ classes: TWClasses = "input", state: TWState = TWState(), @ViewBuilder content: () -> Content) {
        style = .classes(classes)
        self.state = state
        self.content = content()
    }

    public init(_ first: TWStyle, _ styles: TWStyle..., state: TWState = TWState(), @ViewBuilder content: () -> Content) {
        style = TWStyle([first] + styles)
        self.state = state
        self.content = content()
    }

    public var body: some View { content.modifier(TWFieldControlModifier(style: style, state: state)) }
}

/// A field part that accepts either localized text or custom native content.
public struct CNFieldLabel<Content: View>: View {
    private let classes: TWClasses
    private let content: Content

    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.content = content()
    }

    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes
        content = Text(title)
    }

    public var body: some View { content.tw(cn("field-label", classes)) }
}

/// A field part that accepts either localized text or custom native content.
public struct CNFieldDescription<Content: View>: View {
    private let classes: TWClasses
    private let content: Content

    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.content = content()
    }

    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes
        content = Text(title)
    }

    public var body: some View { content.tw(cn("field-description", classes)) }
}

/// A field part that accepts either localized text or custom native content.
public struct CNFieldError<Content: View>: View {
    private let classes: TWClasses
    private let content: Content

    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.content = content()
    }

    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes
        content = Text(title)
    }

    public var body: some View { content.tw(cn("field-error", classes)) }
}
