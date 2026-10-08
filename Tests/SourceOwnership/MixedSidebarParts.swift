import SwiftUI
import SwiftCN

// Copied and imported parts share the public context from the styling core.
struct MixedSidebarParts: View {
    @State private var visibility: NavigationSplitViewVisibility = .all
    var body: some View {
        CNSidebar(visibility: $visibility) {
            SwiftCN.CNSidebarHeader { Text("Imported header") }
            CNSidebarContent {
                SwiftCN.CNSidebarMenuButton("Imported item", systemImage: "tray", action: {})
                CNSidebarMenuButton("Copied item", systemImage: "folder", action: {})
            }
        } detail: { SwiftCN.CNSidebarTrigger() }
    }
}
