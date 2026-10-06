import SwiftUI
import SwiftCN

struct NativeSelectExample: View {
    @State private var selection = "design"
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNNativeSelect("Workspace", options: options, selection: $selection)

        }
    }
}
