import SwiftUI
import SwiftCN

struct ButtonExample: View {
    @State private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                CNButton("Save changes", action: { count += 1 })
                CNButton("Preview", variant: .outline, action: {})
                CNButton("Delete", role: .destructive, variant: .destructive, action: {})
                Text("Saved \(count) times").tw("text-sm text-mutedForeground")
            }

        }
    }
}
