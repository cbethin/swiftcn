import SwiftUI
import SwiftCN

struct CheckboxExample: View {
    @State private var isOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCheckbox("Accept the terms", isOn: $isOn)

        }
    }
}
