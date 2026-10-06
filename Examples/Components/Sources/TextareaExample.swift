import SwiftUI
import SwiftCN

struct TextareaExample: View {
    @State private var text = "Design system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNTextarea("Project description", text: $text, classes: "h-[120]")

        }
    }
}
