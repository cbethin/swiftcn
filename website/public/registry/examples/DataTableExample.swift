import SwiftUI
import SwiftCN

struct DataTableExample: View {
    private static let options = (1...120).map { CNOption(String($0), title: "Workspace \($0)", detail: $0.isMultiple(of: 2) ? "Team" : "Personal") }
    @State private var rowSelection: Set<String> = []
    @State private var sortOrder: [KeyPathComparator<CNOption<String>>] = []
    @State private var query = ""
    @State private var page = 1
    @State private var showID = true
    @State private var records = CNTableRecords(options)
    var body: some View {
        let slice = records.page(page, size: 20)
        VStack(alignment: .leading, spacing: 12) {
            CNInput("Filter workspaces…", text: $query)
            CNCheckbox("Show ID column", isOn: $showID).disabled(!supportsColumnVisibility)
            table(slice.rows)
            CNPagination(page: $page, pageCount: slice.pageCount)
            Text("\(slice.totalCount) matches · \(rowSelection.count) selected across pages")
                .tw("text-xs text-mutedForeground")
        }
        .onChange(of: query) { _, _ in prepare(); page = 1 }
        .onChange(of: sortOrder) { _, _ in prepare() }
    }
    @ViewBuilder private func table(_ rows: [CNOption<String>]) -> some View {
        if #available(macOS 14.4, iOS 17.4, *) {
            configurableTable(rows)
        } else {
            CNDataTable(rows, selection: $rowSelection, sortOrder: $sortOrder, rowsAreSorted: true, classes: "h-[260]") {
                TableColumn("Workspace", value: \.title, content: workspace)
                TableColumn("ID", value: \.id)
            }
        }
    }
    @available(macOS 14.4, iOS 17.4, *)
    private func configurableTable(_ rows: [CNOption<String>]) -> some View {
        CNDataTable(rows, selection: $rowSelection, sortOrder: $sortOrder, rowsAreSorted: true, classes: "h-[260]") {
            TableColumn("Workspace", value: \.title, content: workspace)
            if showID { TableColumn("ID", value: \.id) }
        }
    }
    private func workspace(_ option: CNOption<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(option.title)
            if let detail = option.detail { Text(detail).tw("text-xs text-mutedForeground") }
        }
    }
    private var supportsColumnVisibility: Bool {
        if #available(macOS 14.4, iOS 17.4, *) { true } else { false }
    }
    private func prepare() {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        records = CNTableRecords(Self.options, sortOrder: sortOrder) {
            query.isEmpty || $0.title.localizedStandardContains(query) || ($0.detail?.localizedStandardContains(query) ?? false)
        }
    }
}
