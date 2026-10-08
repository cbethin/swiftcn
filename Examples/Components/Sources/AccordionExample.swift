import SwiftUI
import SwiftCN

struct AccordionExample: View {
    @State private var expanded: Set<String> = []
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAccordion(options, expanded: $expanded, mode: .single) { option in
                Text("Native disclosure content for \(option.title). ").tw("text-sm text-mutedForeground")
            } label: { option in Text(option.title) }

        }
    }
}
