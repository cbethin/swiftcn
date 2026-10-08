import SwiftUI
import SwiftCN

struct LabelExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNLabel { Label("Notifications", systemImage: "bell") }

        }
    }
}
