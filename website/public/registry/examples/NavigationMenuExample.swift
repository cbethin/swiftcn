import SwiftUI
import SwiftCN

struct NavigationMenuExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNNavigationMenu {
                Link("Documentation", destination: URL(string: "https://cbethin.github.io/swiftcn/docs/")!)
                CNDropdownMenu("Resources") { Link("GitHub", destination: URL(string: "https://github.com/cbethin/swiftcn")!) }
            }

        }
    }
}
