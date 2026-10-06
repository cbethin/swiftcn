import SwiftUI
import SwiftCN

struct TableExample: View {
    @State private var selected: Set<String> = []
    #if os(iOS)
    @ScaledMetric(relativeTo: .body) private var selectionWidth: CGFloat = 72
    #else
    @ScaledMetric(relativeTo: .body) private var selectionWidth: CGFloat = 48
    #endif
    private let invoices = [
        Invoice(id: "INV-001", status: "Paid", method: "Credit card", amount: "$250.00"),
        Invoice(id: "INV-002", status: "Pending", method: "Bank transfer", amount: "$150.00"),
        Invoice(id: "INV-003", status: "Paid", method: "Apple Pay", amount: "$350.00"),
        Invoice(id: "INV-004", status: "Overdue", method: "Credit card", amount: "$450.00")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAdaptiveActionLayout(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent invoices").tw("text-lg font-semibold")
                    Text("Keep track of your team's payments.").tw("text-sm text-mutedForeground")
                }
                CNBadge("4 invoices", classes: "bg-accent text-mutedForeground")
            }
            CNTable {
                CNTableRow {
                    CNTableHead("w-[\(selectionWidth)] px-3") { Text("") }
                    CNTableHead("Invoice")
                    CNTableHead("Status")
                    CNTableHead("Payment method")
                    CNTableHead("Amount", alignment: .trailing)
                }
                ForEach(invoices) { invoice in
                    CNTableRow(isSelected: selected.contains(invoice.id), onSelect: {
                        if !selected.insert(invoice.id).inserted { selected.remove(invoice.id) }
                    }) {
                        CNTableCell("w-[\(selectionWidth)] px-3") {
                            CNCheckbox("", isOn: Binding(
                                get: { selected.contains(invoice.id) },
                                set: { if $0 { selected.insert(invoice.id) } else { selected.remove(invoice.id) } }))
                                .accessibilityLabel("Select invoice \(invoice.id)")
                        }
                        CNTableCell("\(invoice.id)", classes: "font-medium")
                        CNTableCell {
                            HStack(spacing: 6) {
                                Circle().tw("w-[6] h-[6] \(invoice.status == "Paid" ? "text-[#16a34a]" : invoice.status == "Overdue" ? "text-destructive" : "text-mutedForeground")").accessibilityHidden(true)
                                Text(invoice.status)
                            }
                        }
                        CNTableCell("\(invoice.method)", classes: "text-mutedForeground")
                        CNTableCell("\(invoice.amount)", classes: "cn-mono font-medium", alignment: .trailing).cnTextUtilities()
                    }
                }
                CNTableRow(classes: "bg-accent") {
                    CNTableCell("w-[\(selectionWidth)] px-3") { Text("") }
                    CNTableCell("Total", classes: "font-semibold")
                    CNTableCell { Text("") }
                    CNTableCell { Text("") }
                    CNTableCell("$1,200.00", classes: "cn-mono font-semibold", alignment: .trailing).cnTextUtilities()
                }
            }
            CNTableCaption("\(selected.count) of 4 invoices selected. Scroll horizontally to see all columns on smaller screens.")
        }
    }
    private struct Invoice: Identifiable {
        let id: String
        let status: String
        let method: String
        let amount: String
    }
}
