import SwiftUI
import SwiftCN

public struct CNAlert<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.frame(maxWidth: .infinity, alignment: .leading).tw(cn("alert", classes))
    }
}

public struct CNItem<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        HStack(alignment: .center, spacing: spacing) { content }.frame(maxWidth: .infinity, alignment: .leading).tw(cn("item", classes))
    }
}

public struct CNItemContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("", classes))
    }
}

public struct CNItemActions<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        CNAdaptiveActionLayout(spacing: spacing) { content }.tw(classes)
    }
}

public struct CNEmpty<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .center, spacing: spacing) { content }.tw(cn("empty", classes))
    }
}

public struct CNEmptyContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("", classes))
    }
}

public struct CNDialogContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.frame(maxWidth: .infinity, alignment: .leading).tw(cn("dialog", classes))
    }
}

public struct CNDialogHeader<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("", classes))
    }
}

public struct CNDialogFooter<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        CNAdaptiveActionLayout(spacing: spacing, verticalAlignment: .trailing) { content }.frame(maxWidth: .infinity, alignment: .trailing).tw(cn("dialog-footer", classes))
    }
}

public struct CNBubble<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("bubble", classes))
    }
}

public struct CNBubbleGroup<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("", classes))
    }
}

public struct CNMessage<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        HStack(alignment: .top, spacing: spacing) { content }.tw(cn("message", classes))
    }
}

public struct CNMessageContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }.tw(cn("", classes))
    }
}

public struct CNMessageActions<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        CNAdaptiveActionLayout(spacing: spacing) { content }.tw(classes)
    }
}

public struct CNInputGroupAddon<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        HStack(alignment: .center, spacing: spacing) { content }.tw(cn("text-mutedForeground", classes))
    }
}

