import SwiftUI
import SwiftCN
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct GalleryCodePanel: View {
    let source: String
    @State private var copied = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNButtonGroup {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use in SwiftUI").tw("text-lg font-semibold")
                    Text("Add the SwiftCN package to your app target, then copy this example.")
                        .tw("text-sm text-mutedForeground")
                }
                Spacer()
                CNButton(variant: .outline, action: copy) {
                    Label(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark" : "doc.on.doc")
                }.accessibilityLabel(copied ? "Swift code copied" : "Copy Swift code")
            }
            ScrollView([.horizontal, .vertical]) {
                Text(source).font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
            }.frame(height: 280).tw("bg-surface border rounded-lg")
            if ["CNDropdownMenu", "CNPopover", "CNHoverCard", "CNTooltip"].contains(where: source.contains) {
                Text("At your window or screen root: ContentView().cnPopoverHost()")
                    .font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                    .tw("text-mutedForeground")
            }
        }
    }
    private func copy() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(source, forType: .string)
        #else
        UIPasteboard.general.string = source
        #endif
        copied = true
    }
}
