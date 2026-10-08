import SwiftUI
import SwiftCN

struct ProgressExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNProgress("Uploading", value: 0.65)

        }
    }
}
