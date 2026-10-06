import SwiftUI
import SwiftCN

struct SidebarExample: View {
    @State private var optionalSelection: String? = nil
    @State private var visibility: NavigationSplitViewVisibility = .all
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNSidebar(visibility: $visibility) {
                List(options, selection: $optionalSelection) { option in Text(option.title).tag(option.id) }
                    .navigationTitle("Workspaces")
            } detail: { Text(optionalSelection ?? "Choose a workspace") }.tw("h-[260]")

        }
    }
}
