import SwiftUI
import SwiftCN

struct SheetExample: View {
    @State private var presented = false
    @State private var isOn = true

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
