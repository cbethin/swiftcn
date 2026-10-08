import SwiftUI
import SwiftCN

struct SliderExample: View {
    @State private var volume = 0.65

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNSlider("Volume", value: $volume)

        }
    }
}
