import SwiftUI

/// A composable native VStack with editable `card` defaults.
public struct CNCard<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(_ classes: TWClasses = "", spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("card p-0 w-full", classes))
    }
}

/// A composable native VStack with editable `card-header` defaults.
public struct CNCardHeader<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(_ classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("card-header", classes))
    }
}

/// A composable native VStack with editable `card-content` defaults.
public struct CNCardContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("card-content", classes))
    }
}

/// A composable native HStack with editable `card-footer` defaults.
public struct CNCardFooter<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content

    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        CNAdaptiveActionLayout(spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("card-footer", classes))
    }
}

/// Styled content with an optional localized Text convenience initializer.
public struct CNCardTitle<Content: View>: View {
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

    public var body: some View { content.tw(cn("card-title", classes)) }
}

/// Styled content with an optional localized Text convenience initializer.
public struct CNCardDescription<Content: View>: View {
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

    public var body: some View { content.tw(cn("card-description", classes)) }
}
