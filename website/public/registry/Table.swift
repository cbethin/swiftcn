import SwiftUI
import SwiftCN

/// Native Grid parts for tables with rich cells. Use CNDataTable for selectable, sortable records.
public struct CNTable<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public var body: some View { Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) { content }.tw(cn("table", classes)) }
}
public struct CNTableRow<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { GridRow { content } }
}
public struct CNTableCell<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public init(_ text: LocalizedStringKey, classes: TWClasses = "") where Content == Text { self.classes = classes; content = Text(text) }
    public var body: some View { content.tw(cn("table-cell", classes)) }
}
public struct CNTableHead<Content: View>: View {
    private let classes: TWClasses
    private let content: Content
    public init(_ classes: TWClasses = "", @ViewBuilder content: () -> Content) { self.classes = classes; self.content = content() }
    public init(_ text: LocalizedStringKey, classes: TWClasses = "") where Content == Text { self.classes = classes; content = Text(text) }
    public var body: some View { content.tw(cn("table-header", classes)).accessibilityAddTraits(.isHeader) }
}

/// A native column builder supports rich cells and sortable key paths without a dynamic-column OS restriction.
public struct CNDataTable<Row: Identifiable, Columns: TableColumnContent>: View
where Columns.TableRowValue == Row, Columns.TableColumnSortComparator == KeyPathComparator<Row> {
    private let rows: [Row]
    private let columns: Columns
    @Binding private var selection: Set<Row.ID>
    @Binding private var sortOrder: [KeyPathComparator<Row>]
    private let classes: TWClasses
    public init(_ rows: [Row], selection: Binding<Set<Row.ID>>, sortOrder: Binding<[KeyPathComparator<Row>]>,
                classes: TWClasses = "", @TableColumnBuilder<Row, KeyPathComparator<Row>> columns: () -> Columns) {
        self.rows = rows; self.columns = columns(); _selection = selection; _sortOrder = sortOrder; self.classes = classes
    }
    public var body: some View {
        Table(rows.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) { columns }.tw(cn("table", classes))
    }
}
