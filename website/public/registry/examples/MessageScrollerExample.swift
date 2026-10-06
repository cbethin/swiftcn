import SwiftUI
import SwiftCN

struct MessageScrollerExample: View {
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNMessageScroller(options, classes: "h-[160]") { option in
                CNBubble { Text(option.title) }
            }

        }
    }
}
