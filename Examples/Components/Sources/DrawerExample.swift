import SwiftUI
import SwiftCN

// At your screen or window root, install .cnPresentationHost().
struct DrawerExample: View {
    @State private var presented = false

    init(initialPresented: Bool = false) { _presented = State(initialValue: initialPresented) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDrawer(isPresented: $presented) {
                CNDialogTitle("Activity")
                Text("Drag the handle to dismiss. Content keeps native scrolling.")
                CNDialogClose()
            } label: { Text("Show activity") }

        }
    }
}
