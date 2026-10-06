import SwiftUI

public struct CNAlertTitle<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("alert-title", classes)) }
}

public struct CNAlertDescription<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("alert-description", classes)) }
}

public struct CNItemTitle<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("item-title", classes)) }
}

public struct CNItemDescription<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("item-description", classes)) }
}

public struct CNEmptyTitle<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("empty-title", classes)) }
}

public struct CNEmptyDescription<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("empty-description", classes)) }
}

public struct CNKbd<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("kbd", classes)).cnTextUtilities() }
}

public struct CNLabel<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("label", classes)) }
}

public struct CNDialogTitle<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("dialog-title", classes)) }
}

public struct CNDialogDescription<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("dialog-description", classes)) }
}

public struct CNMessageMeta<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.classes = classes; self.content = content()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") where Content == Text {
        self.classes = classes; content = Text(title)
    }
    public var body: some View { content.tw(cn("message-meta", classes)) }
}

