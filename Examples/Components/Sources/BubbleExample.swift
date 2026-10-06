import SwiftUI
import SwiftCN

struct BubbleExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                CNBubble { Text("Can we keep this native?") }
                CNBubble("bg-primary text-onPrimary") { Text("Yes. Bindings and gestures stay in SwiftUI.") }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

        }
    }
}
