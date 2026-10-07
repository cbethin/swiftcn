import SwiftUI
import SwiftCN

struct NativeSplitExample: View {
    @State private var fraction = 0.4
    @State private var draft = "Resize the panes while keeping this draft."
    @State private var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            #if os(macOS)
            HSplitView {
                inspector.tw("min-w-[160] bg-surface")
                editor.tw("min-w-[220] bg-surface")
            }.tw("border rounded-lg")
            #else
            CNResizable(fraction: $fraction, axis: .vertical, minimumFraction: 0.35) { inspector } second: { editor }
                .tw("border rounded-lg")
            #endif
            Text("Native desktop dividers; an explicit fraction and touch handle on mobile.")
                .tw("text-sm text-mutedForeground")
        }.frame(height: 420)
    }
    private var inspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspector").tw("text-lg font-semibold")
            Toggle("Monospaced font", isOn: $monospaced).toggleStyle(.tw("switch", base: .switch))
            Spacer()
        }.tw("p-4")
    }
    private var editor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editor").tw("text-lg font-semibold")
            TextEditor(text: $draft).scrollContentBackground(.hidden)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .accessibilityLabel("Split editor draft")
        }.tw("p-4")
    }
}
