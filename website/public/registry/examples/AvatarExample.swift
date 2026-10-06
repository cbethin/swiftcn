import SwiftUI
import SwiftCN

struct AvatarExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CNAvatar(accessibilityLabel: "Charles Bethin") { Text("CB").tw("text-sm font-semibold") }
                CNAvatar(accessibilityLabel: "Team member", classes: "w-12 h-12") { Image(systemName: "person.fill") }
            }

        }
    }
}
