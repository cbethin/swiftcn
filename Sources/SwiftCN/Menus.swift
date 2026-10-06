import SwiftUI

/// Native menu items keep their roles, shortcuts, submenus, and disabled behavior.
public struct CNDropdownMenu<Label: View, Content: View>: View {
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.classes = classes; self.content = content; self.label = label()
    }
    public init(_ title: LocalizedStringKey, classes: TWClasses = "", @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.init(classes, content: content) { Text(title) }
    }
    public var body: some View { Menu(content: content, label: { label }).tw(cn("menu", classes)) }
}

/// Compose native links, navigation links, and submenu controls without owning the application's navigation path.
public struct CNNavigationMenu<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public var body: some View {
        ScrollView(.horizontal) { HStack(spacing: 12) { content } }.tw(cn("menu", classes))
    }
}
/// In-window menu strip. For application menu-bar commands, use SwiftUI Scene.commands instead.
public struct CNMenubar<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public var body: some View { HStack(spacing: 8) { content }.tw(cn("menu p-1 bg-surface border rounded-md", classes)) }
}

/// Attach native contextual actions to any content, including rows and images.
public struct CNContextMenu<Content: View, MenuItems: View>: View {
    private let classes: TWClasses
    private let content: Content
    private let menuItems: () -> MenuItems
    public init(_ classes: TWClasses = "", @ViewBuilder menuItems: @escaping () -> MenuItems, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.menuItems = menuItems; self.content = content()
    }
    public var body: some View { content.tw(classes).contextMenu(menuItems: menuItems) }
}
