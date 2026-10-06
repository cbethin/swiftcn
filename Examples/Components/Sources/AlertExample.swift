import SwiftUI
import SwiftCN

struct AlertExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAlert {
                Label("Changes saved", systemImage: "checkmark.circle").tw("alert-title")
                CNAlertDescription("Your workspace is up to date.")
            }

        }
    }
}
