import SwiftUI
import SwiftCN

struct SkeletonExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNSkeleton(isLoading: true) {
                VStack(alignment: .leading, spacing: 6) { Text("A workspace title"); Text("Loading a thoughtful description.").tw("text-sm") }
            }

        }
    }
}
