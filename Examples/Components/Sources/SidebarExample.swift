import SwiftUI
import SwiftCN

struct SidebarExample: View {
    @Environment(\.twTheme) private var theme
    @State private var selection = "Overview"
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var mobilePresented = false
    @State private var draft = "Q4 design system"

    init(initialMobilePresented: Bool = false) {
        _mobilePresented = State(initialValue: initialMobilePresented)
    }

    var body: some View {
        CNSidebar(visibility: $visibility, mobilePresented: $mobilePresented) {
            SidebarNavigationExample(selection: $selection)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    CNSidebarTrigger().keyboardShortcut("b", modifiers: .command)
                    Text(selection).tw("text-sm font-semibold")
                    Spacer()
                }.tw("p-2")
                CNSeparator()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CNBadge("Workspace")
                        Text(selection == "Overview" ? "Good morning, Charles" : selection)
                            .tw("text-xl font-semibold")
                        Text("Your team's work, all in one place.").tw("text-sm text-mutedForeground")
                        CNCard {
                            CNCardHeader {
                                CNCardTitle("Current project")
                                CNCardDescription("This draft stays put when the sidebar changes.")
                            }
                            CNCardContent { CNInput("Project name", text: $draft) }
                        }
                    }.tw("p-4 w-full")
                }
            }.tw("bg-background")
        }.tw("h-[480] border rounded-xl")
            .clipShape(RoundedRectangle(cornerRadius: theme.radius(.xl)))
    }
}

private struct SidebarNavigationExample: View {
    @Binding var selection: String
    @Environment(\.cnSidebarContext) private var sidebar
    var body: some View {
        CNSidebarHeader {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill").tw("w-8 h-8 text-xl text-primary")
                if !sidebar.isCollapsed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Acme Studio").tw("text-sm font-semibold")
                        Text("Pro workspace").tw("text-xs text-mutedForeground")
                    }.transition(.opacity)
                    Spacer()
                    if sidebar.isCompact { CNSidebarTrigger() }
                }
            }.tw("p-2")
        }
        CNSidebarContent {
            CNSidebarGroup {
                CNSidebarGroupLabel("Workspace")
                CNSidebarMenu {
                    item("Overview", icon: "square.grid.2x2")
                    item("Inbox", icon: "tray", badge: "4")
                    item("Projects", icon: "folder")
                    CNSidebarMenuSub {
                        item("Design system", icon: "circle.dotted")
                        item("Mobile app", icon: "iphone")
                    }
                    CNSidebarMenuButton("Archived", systemImage: "archivebox", action: {}).disabled(true)
                }
            }
            CNSidebarGroup {
                CNSidebarGroupLabel("Team")
                CNSidebarMenu {
                    item("Members", icon: "person.2")
                    item("Settings", icon: "gearshape")
                }
            }
        }
        CNSidebarFooter {
            CNSeparator()
            CNSidebarMenuButton("Charles Bethin", systemImage: "person.crop.circle", dismissOnSelect: false,
                                action: { selection = "Account" })
        }
    }
    private func item(_ title: String, icon: String, badge: String? = nil) -> some View {
        CNSidebarMenuButton(title, systemImage: icon, isSelected: selection == title, badge: badge,
                           action: { selection = title })
    }
}
