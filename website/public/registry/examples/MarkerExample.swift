import SwiftUI
import SwiftCN

struct MarkerExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                CNMarker(variant: .inline) { CNMarkerIcon { Image(systemName: "checkmark") }; Text("Changes saved") }
                CNMarker("Today", variant: .separator)
            }

        }
    }
}
