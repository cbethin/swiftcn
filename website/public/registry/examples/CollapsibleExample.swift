import SwiftUI
import SwiftCN

struct CollapsibleExample: View {
    @State private var isOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCollapsible(isExpanded: $isOn) { Text("Details keep native disclosure behavior.").tw("text-sm") } label: { Text("Show details") }

        }
    }
}
