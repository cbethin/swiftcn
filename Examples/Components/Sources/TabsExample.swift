import SwiftUI
import SwiftCN

struct TabsExample: View {
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNTabs(selection: $tab, classes: "h-[180]") {
                Text("Account settings").tw("p-4").tabItem { Label("Account", systemImage: "person") }.tag(0)
                Text("Security settings").tw("p-4").tabItem { Label("Security", systemImage: "lock") }.tag(1)
            }

        }
    }
}
