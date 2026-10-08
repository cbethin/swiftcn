import SwiftUI
import SwiftCN

struct SeparatorExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack { Text("Workspace"); CNSeparator(); Text("Settings").tw("text-sm text-mutedForeground") }

        }
    }
}
