import SwiftUI
import SwiftCN

struct FieldExample: View {
    @State private var text = "Design system"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNField(isInvalid: text.isEmpty) {
                CNFieldLabel("Workspace name")
                CNInput("Name", text: $text)
                CNFieldDescription("A name your team will recognize.")
                if text.isEmpty { CNFieldError("Enter a workspace name.") }
            }

        }
    }
}
