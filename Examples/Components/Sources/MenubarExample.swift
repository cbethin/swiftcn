import SwiftUI
import SwiftCN

struct MenubarExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNMenubar {
                CNDropdownMenu("File") { Button("New") {}; Button("Open") {} }
                CNDropdownMenu("Edit") { Button("Undo") {}; Button("Redo") {} }
            }

        }
    }
}
