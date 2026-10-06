import SwiftUI
import SwiftCN

struct DrawerExample: View {
    @State private var presented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDrawer(isPresented: $presented) {
                CNDialogTitle("Activity")
                Text("On iOS, drag between medium and large detents. macOS uses a native sheet.")
                CNDialogClose()
            } label: { Text("Show activity") }

        }
    }
}
