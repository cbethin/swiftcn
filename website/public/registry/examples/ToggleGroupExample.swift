import SwiftUI
import SwiftCN

struct ToggleGroupExample: View {
    @State private var rowSelection: Set<String> = []
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNToggleGroup(options, selection: $rowSelection)

        }
    }
}
