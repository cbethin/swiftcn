import SwiftUI
import SwiftCN

struct ToggleExample: View {
    @State private var isOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNToggle(isOn: $isOn) { Label("Bold", systemImage: "bold") }

        }
    }
}
