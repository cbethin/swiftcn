import SwiftUI
import SwiftCN

struct InputGroupExample: View {
    @State private var text = "Design system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNInputGroup {
                CNInputGroupAddon { Image(systemName: "magnifyingglass").accessibilityHidden(true) }
                CNInputGroupField("Search projects", text: $text)
                CNButton("Search", variant: .ghost, size: .small, action: {})
            }

        }
    }
}
