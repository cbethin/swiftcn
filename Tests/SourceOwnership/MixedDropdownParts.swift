import SwiftUI
import SwiftCN

// Copied menu surfaces and imported parts use one shared public focus/dismiss context.
struct MixedDropdownParts: View {
    @State private var presented = false
    @State private var checked = false
    var body: some View {
        CNDropdownMenu("Actions", isPresented: $presented) {
            SwiftCN.CNDropdownMenuItem("Imported item", action: {})
            CNDropdownMenuCheckboxItem(isOn: $checked) { Text("Copied checkbox") }
        }
        SwiftCN.CNDropdownMenuContent {
            CNDropdownMenuItem("Copied item", action: {})
        }
    }
}
