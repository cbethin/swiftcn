import SwiftUI
import SwiftCN

struct CardExample: View {
    @State private var text = "Design system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCard {
                CNCardHeader { CNCardTitle("New workspace"); CNCardDescription("Keep your team in sync.") }
                CNCardContent { CNInput("Workspace name", text: $text) }
                CNCardFooter { CNButton("Create", action: {}) }
            }

        }
    }
}
