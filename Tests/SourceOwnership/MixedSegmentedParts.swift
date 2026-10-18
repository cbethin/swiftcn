import SwiftUI
import SwiftCN

struct MixedSegmentedParts: View {
    @State private var selection = 0
    var body: some View {
        VStack {
            SwiftCN.CNSegmentedControl(selection: $selection) {
                CNSegment(0, title: "Copied segment")
                SwiftCN.CNSegment(1, title: "Imported segment")
            }
            CNSegmentedControl(selection: $selection) {
                SwiftCN.CNSegment(0, title: "Imported segment")
                CNSegment(1, title: "Copied segment")
            }
        }
    }
}
