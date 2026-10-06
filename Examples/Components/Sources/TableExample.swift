import SwiftUI
import SwiftCN

struct TableExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNTable {
                CNTableRow { CNTableHead("Workspace"); CNTableHead("Status") }
                CNTableRow { CNTableCell("Design system"); CNTableCell { CNBadge("Ready") } }
                CNTableRow { CNTableCell("Mobile app"); CNTableCell("In progress") }
            }

        }
    }
}
