import SwiftUI
import SwiftCN

struct KbdExample: View {
    @State private var presented = false
    @State private var selection: String?
    private let options = [
        CNOption("button", title: "Button", detail: "Actions and keyboard shortcuts", systemImage: "cursorarrow.click"),
        CNOption("calendar", title: "Calendar", detail: "Choose a date", systemImage: "calendar"),
        CNOption("resizable", title: "Resizable", detail: "Adjust panel sizes", systemImage: "rectangle.split.2x1")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNButton(variant: .outline, action: { presented = true }) {
                HStack(spacing: 12) {
                    Text("Search")
                    CNKbd("⌘ K").accessibilityLabel("Command K")
                }
            }
            .keyboardShortcut("k", modifiers: .command)
            .sheet(isPresented: $presented) {
                CNDialogContent("min-w-[300]") {
                    CNDialogHeader {
                        CNDialogTitle("Search components")
                        CNDialogDescription("Type to filter, then choose a component.")
                    }
                    CNCommand(options, selection: $selection, classes: "h-[240]") { _ in presented = false }
                    CNDialogFooter { CNDialogClose() }
                }
            }
            Text(selection.flatMap { id in options.first { $0.id == id }?.title }
                 .map { "Selected: \($0)" } ?? "Click Search or press ⌘ K.")
                .tw("text-sm text-mutedForeground")
        }
    }
}
