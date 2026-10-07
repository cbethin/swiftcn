import SwiftUI
import SwiftCN

// At your screen or window root, install .cnPresentationHost().
struct SheetExample: View {
    @State private var presented = false
    @State private var isOn = true

    init(initialPresented: Bool = false) { _presented = State(initialValue: initialPresented) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNSheet(isPresented: $presented) {
                CNDialogTitle("Workspace settings")
                CNSwitch("Notifications", isOn: $isOn)
                CNDialogClose()
            } label: { Text("Settings") }

        }
    }
}
