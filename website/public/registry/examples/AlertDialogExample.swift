import SwiftUI
import SwiftCN

struct AlertDialogExample: View {
    @State private var text = ""
    @State private var presented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAlertDialog("Delete workspace?", isPresented: $presented) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { text = "Deleted" }
            } message: { Text("This action removes the workspace.") } label: { Text("Delete workspace") }

        }
    }
}
