import SwiftUI

/// Intrinsic column widths for small, rich tables. Use CNDataTable for large record sets.
public struct CNTable<Content: View>: View {
    @State private var viewportWidth: CGFloat = 0
    @Environment(\.twTheme) private var theme
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) { content }
                .frame(minWidth: viewportWidth, alignment: .leading)
        }.fixedSize(horizontal: false, vertical: true)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { viewportWidth = $0 }
            .tw(cn("table", classes)).clipShape(RoundedRectangle(cornerRadius: theme.radius(.lg)))
    }
}
public struct CNTableRow<Content: View>: View {
    private let isSelected: Bool
    private let onSelect: (() -> Void)?
    private let classes: TWClasses
    private let content: Content
    public init(isSelected: Bool = false, onSelect: (() -> Void)? = nil, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected; self.onSelect = onSelect; self.classes = classes; self.content = content()
    }
    public var body: some View {
        GridRow { content }.tw(cn("table-row", isSelected ? "table-row-selected" : "", classes))
            .environment(\.cnTableRowAction, onSelect)
            .overlay(alignment: .bottom) { CNSeparator().allowsHitTesting(false) }
            .accessibilityElement(children: .contain).accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityActions {
                if let onSelect { Button("Toggle row selection", action: onSelect) }
            }
    }
}
private struct CNTableRowAction: EnvironmentKey {
    static var defaultValue: (() -> Void)? { nil }
}
private extension EnvironmentValues {
    var cnTableRowAction: (() -> Void)? {
        get { self[CNTableRowAction.self] }
        set { self[CNTableRowAction.self] = newValue }
    }
}
private struct CNTableCellActivation: ViewModifier {
    @Environment(\.cnTableRowAction) private var onSelect
    @Environment(\.isEnabled) private var isEnabled
    func body(content: Content) -> some View {
        content.contentShape(.interaction, Rectangle())
            .gesture(TapGesture().onEnded { if isEnabled { onSelect?() } },
                     including: onSelect == nil ? .subviews : .all)
    }
}
public struct CNTableCell<Content: View>: View {
    private let alignment: Alignment
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", alignment: Alignment = .leading, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.alignment = alignment; self.content = content()
    }
    public init(_ text: LocalizedStringKey, classes: TWClasses = "", alignment: Alignment = .leading) where Content == Text {
        self.classes = classes; self.alignment = alignment; content = Text(text)
    }
    public var body: some View {
        content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment).tw(cn("table-cell", classes))
            .modifier(CNTableCellActivation())
            .gridColumnAlignment(alignment.horizontal)
    }
}
public struct CNTableHead<Content: View>: View {
    private let alignment: Alignment
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", alignment: Alignment = .leading, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.alignment = alignment; self.content = content()
    }
    public init(_ text: LocalizedStringKey, classes: TWClasses = "", alignment: Alignment = .leading) where Content == Text {
        self.classes = classes; self.alignment = alignment; content = Text(text)
    }
    public var body: some View {
        content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment).tw(cn("table-header", classes))
            .gridColumnAlignment(alignment.horizontal).accessibilityAddTraits(.isHeader)
    }
}
public struct CNTableCaption: View {
    private let title: LocalizedStringKey
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, classes: TWClasses = "") { self.title = title; self.classes = classes }
    public var body: some View { Text(title).tw(cn("table-caption", classes)) }
}

/// A native column builder supports rich cells and sortable key paths without a dynamic-column OS restriction.
public struct CNDataTable<Row: Identifiable, Columns: TableColumnContent>: View
where Row.ID: Sendable, Columns.TableRowValue == Row, Columns.TableColumnSortComparator == KeyPathComparator<Row> {
    private let rows: [Row]
    private let columns: Columns
    @Binding private var selection: Set<Row.ID>
    @Binding private var sortOrder: [KeyPathComparator<Row>]
    private let rowsAreSorted: Bool
    private let selectionScope: CNTableSelection<Row.ID>
    private let classes: TWClasses
    public init(_ rows: [Row], selection: Binding<Set<Row.ID>>, sortOrder: Binding<[KeyPathComparator<Row>]>,
                rowsAreSorted: Bool = false, classes: TWClasses = "",
                @TableColumnBuilder<Row, KeyPathComparator<Row>> columns: () -> Columns) {
        self.rows = rows; self.rowsAreSorted = rowsAreSorted
        selectionScope = CNTableSelection(Set(rows.map(\.id)))
        self.columns = columns(); _selection = selection; _sortOrder = sortOrder; self.classes = classes
    }
    public var body: some View {
        Table(rowsAreSorted || sortOrder.isEmpty ? rows : rows.sorted(using: sortOrder),
              selection: selectionScope.binding($selection), sortOrder: $sortOrder) { columns }.tw(cn("data-table", classes)).cnControlUtilities()
    }
}

/// Native selection edits only the visible records. The host owns selections on other pages.
/// Use stable value IDs, such as UUID, String, or Int, that conform to Sendable.
public struct CNTableSelection<ID: Hashable & Sendable>: Sendable {
    private let visible: Set<ID>
    public init(_ visible: Set<ID>) { self.visible = visible }
    public func binding(_ selection: Binding<Set<ID>>) -> Binding<Set<ID>> {
        Binding(get: { selection.wrappedValue.intersection(visible) }, set: { replacement in
            selection.wrappedValue = selection.wrappedValue.subtracting(visible).union(replacement.intersection(visible))
        })
    }
}

/// Prepare records when data, filters, or ordering change. Paging only slices this snapshot.
/// Keep selection keyed by record ID in the host, including records on other pages.
public struct CNTableRecords<Row> {
    public let rows: [Row]
    public init(_ rows: [Row], sortOrder: [KeyPathComparator<Row>] = [], filter: ((Row) -> Bool)? = nil) {
        let filtered = filter.map { rows.filter($0) } ?? rows
        self.rows = sortOrder.isEmpty || filtered.count < 2 ? filtered : filtered.sorted(using: sortOrder)
    }
    public func page(_ number: Int, size: Int = 50) -> CNTablePage<Row> {
        precondition(size > 0, "Page size must be positive.")
        let count = rows.count / size + (rows.count % size == 0 ? 0 : 1)
        let page = count == 0 ? 0 : min(count, max(1, number))
        let start = page == 0 ? 0 : (page - 1) * size
        let end = start + min(size, rows.count - start)
        return CNTablePage(rows: Array(rows[start..<end]), number: page, pageCount: count, totalCount: rows.count)
    }
}
public struct CNTablePage<Row> {
    public let rows: [Row]
    public let number: Int
    public let pageCount: Int
    public let totalCount: Int
}
