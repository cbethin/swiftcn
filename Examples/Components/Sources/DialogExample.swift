import SwiftUI
import SwiftCN

struct DialogExample: View {
    @State private var text = "Design system"
    @State private var presented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDialog(isPresented: $presented) {
                CNDialogHeader { CNDialogTitle("Edit workspace"); CNDialogDescription("Update the native fields below.") }
                CNInput("Name", text: $text)
                CNDialogFooter { CNDialogClose(); CNButton("Save", action: { presented = false }) }
            } label: { Text("Edit workspace") }

        }
    }
}
