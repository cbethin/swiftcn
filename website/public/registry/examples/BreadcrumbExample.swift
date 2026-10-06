import SwiftUI
import SwiftCN

struct BreadcrumbExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNBreadcrumb {
                Link("Home", destination: URL(string: "https://cbethin.github.io/swiftcn/")!)
                CNBreadcrumbSeparator()
                CNBreadcrumbPage("Components")
            }

        }
    }
}
