import SwiftUI
import SwiftCN

struct ResizableExample: View {
    @State private var fraction = 0.35

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNResizable(fraction: $fraction, classes: "h-[160]") {
                Text("Sidebar").tw("p-4 w-full")
            } second: { Text("Editor").tw("p-4 w-full") }

        }
    }
}
