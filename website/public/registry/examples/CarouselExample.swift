import SwiftUI
import SwiftCN

struct CarouselExample: View {
    @State private var optionalSelection: String? = nil
    private let options = [CNOption("design", title: "Design system"), CNOption("mobile", title: "Mobile app"), CNOption("archive", title: "Archived", isDisabled: true)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCarousel(options, selection: $optionalSelection, classes: "h-[160]") { option in
                CNCard {
                    CNCardHeader {
                        CNCardTitle { Text(option.title) }
                        CNCardDescription("Swipe or scroll to the next page.")
                    }
                }.tw("p-4")
            }

        }
    }
}
