import SwiftUI
import SwiftCN

struct DropdownMenuExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNDropdownMenu("Workspace actions") {
                Button("Rename") {}
                Divider()
                Button("Delete", role: .destructive) {}
            }

        }
    }
}
