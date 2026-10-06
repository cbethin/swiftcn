import SwiftUI
import SwiftCN

// This fixture compiles with copied selectors and the imported command component.
// Their option model must remain the same public type across the module boundary.
struct MixedComponentOptions: View {
    @State private var selection = "design"
    @State private var commandSelection: String?

    var body: some View {
        let options = [CNOption("design", title: "Design system")]
        VStack {
            CNSelect("Workspace", options: options, selection: $selection)
            SwiftCN.CNCommand(options, selection: $commandSelection) { _ in }
        }
    }
}
