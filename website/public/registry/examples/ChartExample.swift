import SwiftUI
import SwiftCN
import Charts

struct ChartExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNChart("h-[200]") {
                ForEach(Array([12, 18, 14, 24].enumerated()), id: \.offset) { index, value in
                    BarMark(x: .value("Week", "Week \(index + 1)"), y: .value("Downloads", value), width: .ratio(0.55))
                }
            }.accessibilityLabel("Downloads by week")

        }
    }
}
