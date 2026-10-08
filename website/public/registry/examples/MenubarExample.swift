import SwiftUI
import SwiftCN

struct MenubarExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNMenubar {
                CNDropdownMenu("File") { CNDropdownMenuItem("New") {}; CNDropdownMenuItem("Open") {} }
                CNDropdownMenu("Edit") { CNDropdownMenuItem("Undo") {}; CNDropdownMenuItem("Redo") {} }
            }

        }
    }
}
