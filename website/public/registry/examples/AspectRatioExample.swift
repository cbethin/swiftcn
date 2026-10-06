import SwiftUI
import SwiftCN

struct AspectRatioExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAspectRatio(16 / 9) {
                Image(systemName: "photo").tw("text-3xl w-full bg-accent rounded-lg")
            }.tw("w-full")

        }
    }
}
