import SwiftUI
import SwiftCN

struct DataTableExample: View {
    @State private var rowSelection: Set<String> = []
    @State private var sortOrder: [KeyPathComparator<CNOption<String>>] = []
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDataTable(options, selection: $rowSelection, sortOrder: $sortOrder, classes: "h-[220]") {
                TableColumn("Workspace", value: \.title)
                TableColumn("ID", value: \.id)
            }

        }
    }
}
