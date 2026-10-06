import SwiftUI
import SwiftCN

struct SpinnerExample: View {
    @State private var paused = false
    private var motion: TWClasses { paused ? "cn-spin-[0]" : "" }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                CNSpinner("Loading workspace", classes: cn("w-6 h-6", motion))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Getting things ready").tw("text-sm font-semibold")
                    Text("Your workspace is on its way.").tw("text-sm text-mutedForeground")
                }
            }
            HStack(spacing: 20) {
                CNSpinner("Small activity", lineWidth: 1.5, classes: cn("w-4 h-4", motion))
                CNSpinner("Activity", classes: motion)
                CNSpinner("Large activity", lineWidth: 3, classes: cn("w-8 h-8 text-[#6366f1]", motion))
            }.accessibilityElement(children: .contain)
            CNButton(paused ? "Resume animation" : "Pause animation", variant: .outline) { paused.toggle() }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
