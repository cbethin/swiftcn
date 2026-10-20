import SwiftUI
import SwiftCN

struct SegmentedControlExample: View {
    enum Mode: String, CaseIterable { case preview = "Preview", code = "Code", split = "Split" }
    @State private var mode = Mode.preview

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CNSegmentedControl(selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { value in
                    CNSegment(value, title: LocalizedStringKey(value.rawValue))
                }
            }.accessibilityLabel("Workspace view")
            Text("Selected: \(mode.rawValue)").tw("text-sm text-mutedForeground")
        }
    }
}
