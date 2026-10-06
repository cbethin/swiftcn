import SwiftUI
import SwiftCN

struct HoverCardExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNHoverCard {
                CNDialogTitle("swiftcn")
                CNDialogDescription("Composable styling for native SwiftUI.")
            } label: { Text("About swiftcn") }

        }
    }
}
