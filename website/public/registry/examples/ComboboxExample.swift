import SwiftUI
import SwiftCN

struct ComboboxExample: View {
    @State private var optionalSelection: String? = nil
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCombobox("Choose a workspace", options: options, selection: $optionalSelection)

        }
    }
}
