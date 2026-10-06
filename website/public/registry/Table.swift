import SwiftUI
import SwiftCN

/// Native Grid parts for tables with rich cells. Use CNDataTable for selectable, sortable records.
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
            .background(GeometryReader { proxy in Color.clear.preference(key: CNTableWidthKey.self, value: proxy.size.width) })
            .onPreferenceChange(CNTableWidthKey.self) { viewportWidth = $0 }
            .tw(cn("table", classes)).clipShape(RoundedRectangle(cornerRadius: theme.radius(.lg)))
    }
}
private struct CNTableWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
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
            .background {
                if let onSelect {
                    Button(action: onSelect) { Color.clear.contentShape(.interaction, Rectangle()) }
                        .buttonStyle(.plain).focusable(false).accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottom) { CNSeparator().allowsHitTesting(false) }
            .accessibilityElement(children: .contain).accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityActions {
                if let onSelect { Button("Toggle row selection", action: onSelect) }
            }
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
