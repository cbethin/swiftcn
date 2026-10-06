import SwiftUI
import SwiftCN

struct CalendarExample: View {
    @State private var date = Date(timeIntervalSince1970: 1_760_054_400)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNCalendar("Delivery date", selection: $date)

        }
    }
}
