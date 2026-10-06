import SwiftUI
import SwiftCN

public struct CNBreadcrumb<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public var body: some View {
        HStack(spacing: 8) { content }.tw(cn("breadcrumb", classes)).accessibilityElement(children: .contain)
            .accessibilityLabel("Breadcrumb")
    }
}
public struct CNBreadcrumbSeparator: View {
    public init() {}
    public var body: some View { Image(systemName: "chevron.forward").tw("text-xs text-mutedForeground").accessibilityHidden(true) }
}
public struct CNBreadcrumbPage: View {
    private let title: LocalizedStringKey
    public init(_ title: LocalizedStringKey) { self.title = title }
    public var body: some View { Text(title).tw("text-sm text-foreground").accessibilityAddTraits(.isSelected) }
}
public struct CNPagination: View {
    @Binding private var page: Int
    private let pageCount: Int
    private let classes: TWClasses
    public init(page: Binding<Int>, pageCount: Int, classes: TWClasses = "") {
        _page = page; self.pageCount = max(0, pageCount); self.classes = classes
    }
    /// Bounded work even for thousands of pages; page numbers are one-based.
    public nonisolated static func visiblePages(page: Int, pageCount: Int) -> [Int] {
        guard pageCount > 0 else { return [] }
        let current = min(pageCount, max(1, page))
        return Array(Set([1, pageCount] + Array(max(1, current - 2)...(current + min(2, pageCount - current))))).sorted()
    }
    public var body: some View {
        HStack(spacing: 4) {
            CNButton("Previous", variant: .ghost, action: { page = max(1, page - 1) }).disabled(pageCount == 0 || page <= 1)
            let pages = Self.visiblePages(page: page, pageCount: pageCount)
            ForEach(Array(pages.enumerated()), id: \.element) { index, number in
                if index > 0 && number - pages[index - 1] > 1 { Text("…").accessibilityHidden(true) }
                CNButton(variant: number == page ? .primary : .ghost, size: .small, action: { page = number }) {
                    Text(number, format: .number)
                }.accessibilityLabel("Page \(number)").accessibilityAddTraits(number == page ? .isSelected : [])
            }
            CNButton("Next", variant: .ghost, action: { page = min(pageCount, page + 1) }).disabled(pageCount == 0 || page >= pageCount)
        }.tw(cn("pagination", classes))
            .onChange(of: page) { _, value in
                let normalized = pageCount == 0 ? 0 : min(pageCount, max(1, value))
                if page != normalized { page = normalized }
            }
            .onChange(of: pageCount, initial: true) { _, count in
                let normalized = count == 0 ? 0 : min(count, max(1, page))
                if page != normalized { page = normalized }
            }
    }
}
/// Native TabView keeps native tab semantics and each child's tagged identity.
public struct CNTabs<Selection: Hashable, Content: View>: View {
    @Binding private var selection: Selection
    private let classes: TWClasses
    private let content: Content
    public init(selection: Binding<Selection>, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        _selection = selection; self.classes = classes; self.content = content()
    }
    public var body: some View { TabView(selection: $selection) { content }.tw(cn("tabs", classes)).cnControlUtilities() }
}
public struct CNSidebar<Sidebar: View, Detail: View>: View {
    @Binding private var visibility: NavigationSplitViewVisibility
    private let classes: TWClasses
    private let sidebar: Sidebar
    private let detail: Detail
    public init(visibility: Binding<NavigationSplitViewVisibility>, classes: TWClasses = "",
                @ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
        _visibility = visibility; self.classes = classes; self.sidebar = sidebar(); self.detail = detail()
    }
    public var body: some View {
        NavigationSplitView(columnVisibility: $visibility) { sidebar } detail: { detail }.tw(cn("sidebar", classes))
    }
}
