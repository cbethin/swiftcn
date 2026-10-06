import SwiftUI
import SwiftCN

struct ButtonGroupExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNButtonGroup {
                CNButton("Previous", variant: .outline, action: {})
                CNButton("Next", variant: .outline, action: {})
                CNDropdownMenu("More") { Button("Export") {} }
            }

        }
    }
}
