import SwiftUI
import SwiftCN

struct AspectRatioExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAspectRatio(16 / 9, classes: "bg-accent rounded-lg") {
                Image(systemName: "photo").tw("text-3xl text-mutedForeground")
            }.tw("w-full")

        }
    }
}
