import SwiftUI

/// Native sheet presentation. The binding remains the application's source of truth.
public struct CNDialog<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .sheet(isPresented: $isPresented) {
                CNDialogContent { content() }
            }
    }
}

/// Native sheet presentation. The binding remains the application's source of truth.
public struct CNSheet<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .sheet(isPresented: $isPresented) {
                CNDialogContent { content() }
            }
    }
}

/// Native sheet presentation. The binding remains the application's source of truth.
public struct CNDrawer<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .sheet(isPresented: $isPresented) {
                CNDialogContent { content() }
            .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
    }
}

/// Alert buttons use native roles and placement. The operating system owns the alert surface.
public struct CNAlertDialog<Label: View, Actions: View, Message: View>: View {
    private let title: LocalizedStringKey
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let label: Label
    private let actions: () -> Actions
    private let message: () -> Message
    public init(_ title: LocalizedStringKey, isPresented: Binding<Bool>, classes: TWClasses = "",
                @ViewBuilder actions: @escaping () -> Actions, @ViewBuilder message: @escaping () -> Message,
                @ViewBuilder label: () -> Label) {
        self.title = title; _isPresented = isPresented; self.classes = classes
        self.actions = actions; self.message = message; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .alert(title, isPresented: $isPresented, actions: actions, message: message)
    }
}
public struct CNDialogClose<Label: View>: View {
    @Environment(\.dismiss) private var dismiss
    private let label: Label
    private let classes: TWClasses
    public init(_ classes: TWClasses = "", @ViewBuilder label: () -> Label) { self.classes = classes; self.label = label() }
    public init(_ title: LocalizedStringKey = "Close", classes: TWClasses = "") where Label == Text {
        self.classes = classes; self.label = Text(title)
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { dismiss() }) { label }.keyboardShortcut(.cancelAction)
    }
}
public struct CNPopover<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let edge: Edge
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, arrowEdge: Edge = .top, classes: TWClasses = "",
                @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; edge = arrowEdge; self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented.toggle() }) { label }
            .popover(isPresented: $isPresented, arrowEdge: edge) { content().tw("popover") }
    }
}
public struct CNHoverCard<Label: View, Content: View>: View {
    @State private var isPresented = false
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNPopover(isPresented: $isPresented, classes: classes) { content().tw("hover-card") } label: { label }
            .onHover { hovering in if hovering { isPresented = true } }
    }
}
public struct CNTooltip<Label: View>: View {
    private let text: LocalizedStringKey
    private let classes: TWClasses
    private let label: Label
    @State private var isPresented = false
    public init(_ text: LocalizedStringKey, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        self.text = text; self.classes = classes; self.label = label()
    }
    public var body: some View {
        #if os(macOS)
        label.help(Text(text)).tw(cn("tooltip", classes))
        #else
        CNPopover(isPresented: $isPresented, classes: classes) { Text(text).tw("tooltip") } label: { label }
        #endif
    }
}
