import SwiftUI
import SwiftCN

struct DrawerExample: View {
    @State private var presented = false
    private let showsInlinePreview: Bool

    init(showsInlinePreview: Bool = false) { self.showsInlinePreview = showsInlinePreview }

    var body: some View {
        if showsInlinePreview {
            // Snapshot the shared content; the live example uses the system sheet.
            CNDrawerContent { drawerContent }
        } else {
            CNDrawer(isPresented: $presented) { drawerContent } label: { Text("Show activity") }
        }
    }

    private var drawerContent: some View {
        Group {
            CNDialogTitle("Activity")
            Text("A native sheet handles resizing, dragging, and dismissal.")
                .tw("text-sm text-mutedForeground")
            CNDialogClose()
        }
    }
}
