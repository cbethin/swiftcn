import SwiftUI
import SwiftCN

struct DropdownMenuExample: View {
    var showsInlinePreview = false
    @State private var notifications = true
    @State private var lastAction = "No action selected"

    private var actions: some View {
        Group {
            CNDropdownMenuLabel("Workspace")
            CNDropdownMenuItem(action: { lastAction = "Rename selected" }) {
                Image(systemName: "pencil").tw("w-4")
                Text("Rename")
                Spacer()
                CNDropdownMenuShortcut("⌘R")
            }
            CNDropdownMenuItem(action: { lastAction = "Duplicate selected" }) {
                Image(systemName: "square.on.square").tw("w-4")
                Text("Duplicate")
            }
            CNDropdownMenuSeparator()
            CNDropdownMenuCheckboxItem(isOn: $notifications) { Text("Notifications") }
            CNDropdownMenuSeparator()
            CNDropdownMenuItem(role: .destructive, action: { lastAction = "Delete selected" }) {
                Image(systemName: "trash").tw("w-4")
                Text("Delete workspace")
            }
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CNDropdownMenu("Workspace actions") { actions }
            if showsInlinePreview {
                // Image captures show the parts without opening a second window.
                CNDropdownMenuContent("border max-w-[260]", autofocus: false) { actions }
            }
            Text(lastAction).tw("text-xs text-mutedForeground")
        }
    }
}
