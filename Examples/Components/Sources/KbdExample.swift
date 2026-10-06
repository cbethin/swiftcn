import SwiftUI
import SwiftCN

struct KbdExample: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.twTheme) private var theme
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
                VStack(spacing: 0) {
                    CNCommand(options, selection: $selection, classes: "h-[230]") { _ in presented = false }
                    CNSeparator()
                    HStack(spacing: 6) {
                        #if os(macOS)
                        Text("↑ ↓ Navigate   ↵ Choose").tw("text-xs text-mutedForeground")
                        #else
                        Text("Choose a component").tw("text-xs text-mutedForeground")
                        #endif
                        Spacer()
                        CNDialogClose("Close", classes: "border-0 text-xs font-medium px-2 py-1")
                    }.tw("px-3 py-2")
                }
                #if os(macOS)
                .tw("w-[380] bg-surface text-foreground")
                #else
                .tw("w-full bg-surface text-foreground")
                .frame(maxHeight: .infinity, alignment: .top)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                #endif
                .presentationBackground(theme.color(.surface, scheme: colorScheme))
                .preferredColorScheme(colorScheme)
            }
            Text(selection.flatMap { id in options.first { $0.id == id }?.title }
                 .map { "Selected: \($0)" } ?? "Click Search or press ⌘ K.")
                .tw("text-sm text-mutedForeground")
        }
    }
}
