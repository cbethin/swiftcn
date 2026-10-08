import SwiftUI
import SwiftCN

struct ScrollAreaExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNScrollArea(classes: "h-[150]") {
                VStack(alignment: .leading, spacing: 12) { ForEach(0..<20) { Text("Project \($0 + 1)") } }.tw("p-3")
            }

        }
    }
}
