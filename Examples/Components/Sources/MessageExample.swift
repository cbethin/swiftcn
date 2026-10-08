import SwiftUI
import SwiftCN

struct MessageExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNMessage {
                CNAvatar(accessibilityLabel: "Charles") { Text("CB") }
                CNMessageContent {
                    CNMessageMeta("Charles · Just now")
                    CNBubble { Text("The components are yours to edit.") }
                    CNMessageActions { CNButton("Reply", variant: .ghost, size: .small, action: {}) }
                }
            }

        }
    }
}
