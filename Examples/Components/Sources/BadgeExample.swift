import SwiftUI
import SwiftCN

struct BadgeExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CNBadge("Released")
                CNBadge("Preview", variant: .secondary)
                CNBadge("Needs attention", classes: "bg-destructive text-onDestructive")
            }

        }
    }
}
