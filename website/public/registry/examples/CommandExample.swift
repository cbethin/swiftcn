import SwiftUI
import SwiftCN

struct CommandExample: View {
    @State private var optionalSelection: String? = nil
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCommand(options, selection: $optionalSelection, classes: "h-[260]")

        }
    }
}
