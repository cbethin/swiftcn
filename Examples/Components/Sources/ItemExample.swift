import SwiftUI
import SwiftCN

struct ItemExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNItem {
                Image(systemName: "folder").accessibilityHidden(true)
                CNItemContent { CNItemTitle("Design system"); CNItemDescription("Shared native components") }
                Spacer()
                CNItemActions { CNButton("Open", variant: .outline, action: {}) }
            }

        }
    }
}
