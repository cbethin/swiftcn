import SwiftUI
import SwiftCN

struct BadgeExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CNBadge("Released")
                CNBadge("Preview", classes: "bg-accent text-onAccent")
                CNBadge("Needs attention", classes: "bg-destructive text-onDestructive")
            }

        }
    }
}
