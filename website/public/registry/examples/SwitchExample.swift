import SwiftUI
import SwiftCN

struct SwitchExample: View {
    @State private var isOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNSwitch("Notifications", isOn: $isOn)

        }
    }
}
