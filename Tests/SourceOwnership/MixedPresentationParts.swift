import SwiftUI
import SwiftCN

// Imported and copied close buttons share one dismiss context, including native sheets.
struct MixedPresentationParts: View {
    @State private var dialog = false
    @State private var drawer = false
    var body: some View {
        VStack {
            CNDialog(isPresented: $dialog) {
                SwiftCN.CNDialogClose()
            } label: { Text("Copied dialog") }
            CNDrawer(isPresented: $drawer) {
                SwiftCN.CNDialogClose()
            } label: { Text("Copied native drawer") }
            SwiftCN.CNDialog(isPresented: $dialog) {
                CNDialogClose()
            } label: { Text("Imported dialog") }
        }
    }
}
