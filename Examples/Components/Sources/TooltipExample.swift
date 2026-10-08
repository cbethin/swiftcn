import SwiftUI
import SwiftCN

struct TooltipExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNTooltip("Download the workspace") {
                Label("Download", systemImage: "arrow.down.to.line").tw("text-sm")
            }

        }
    }
}
