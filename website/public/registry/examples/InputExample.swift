import SwiftUI
import SwiftCN

struct InputExample: View {
    @State private var text = "Design system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNInput("Workspace name", text: $text)

        }
    }
}
