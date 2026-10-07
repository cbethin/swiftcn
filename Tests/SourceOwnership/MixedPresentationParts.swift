import SwiftUI
import SwiftCN

// Imported and copied close buttons share one dismiss context, including native sheets.
struct MixedPresentationParts: View {
    @State private var dialog = false
    @State private var drawer = false
    @State private var detent = PresentationDetent.medium
    var body: some View {
        VStack {
            CNDialog(isPresented: $dialog) {
                SwiftCN.CNDialogClose()
            } label: { Text("Copied dialog") }
            CNDrawer(isPresented: $drawer, detents: [.medium, .large], selection: $detent, onDismiss: {}) {
                SwiftCN.CNDialogClose()
            } label: { Text("Copied native drawer") }
            CNDrawerContent {
                SwiftCN.CNDialogTitle("Copied content with imported parts")
            }
            SwiftCN.CNDrawerContent { CNDialogTitle("Imported content with copied parts") }
            SwiftCN.CNDialog(isPresented: $dialog) {
                CNDialogClose()
            } label: { Text("Imported dialog") }
        }
    }
}
