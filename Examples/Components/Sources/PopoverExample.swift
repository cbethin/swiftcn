import SwiftUI
import SwiftCN

struct PopoverExample: View {
    @State private var presented = false
    @State private var isOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNPopover(isPresented: $presented) {
                CNDialogTitle("Display settings")
                CNSwitch("Show notifications", isOn: $isOn)
            } label: { Text("Display settings") }

        }
    }
}
