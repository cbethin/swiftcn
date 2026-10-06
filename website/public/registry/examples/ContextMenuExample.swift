import SwiftUI
import SwiftCN

struct ContextMenuExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNContextMenu { Button("Duplicate") {}; Button("Delete", role: .destructive) {} } content: {
                CNCard { Text("Right-click or long-press this card.") }
            }

        }
    }
}
