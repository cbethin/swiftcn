import SwiftUI
import SwiftCN

struct NativeNavigationExample: View {
    private enum Destination: String, CaseIterable, Identifiable {
        case inbox = "Inbox", projects = "Projects", archive = "Archive"
        var id: Self { self }
    }
    @State private var selected: Destination? = .projects
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var draft = "A draft stays in caller-owned state."

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(Destination.allCases, selection: $selected) { destination in
                NavigationLink(value: destination) {
                    Label(destination.rawValue, systemImage: "folder")
                        .labelStyle(.tw("sidebar-item-label"))
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .tw("sidebar-list")
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: .infinity)
            .navigationTitle("Workspace")
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                Text(selected?.rawValue ?? "Choose a destination").tw("text-xl font-semibold")
                CNFieldControl("textarea") {
                    TextEditor(text: $draft).scrollContentBackground(.hidden)
                        .accessibilityLabel("Project draft")
                }
                Text("SwiftUI owns column visibility, row selection, and compact navigation.")
                    .tw("text-sm text-mutedForeground")
            }
            .tw("p-6 bg-background")
            .navigationSplitViewColumnWidth(min: 300, ideal: 560, max: .infinity)
            .navigationTitle(selected?.rawValue ?? "Workspace")
        }
    }
}
