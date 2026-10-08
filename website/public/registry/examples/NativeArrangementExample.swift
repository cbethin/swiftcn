import SwiftUI
import SwiftCN

/// Use this as a screen root. Keep navigation outside the native arrangement.
struct NativeArrangementExample: View {
    @State private var draft = "Edit this draft, then fold or resize the window."
    @State private var monospaced = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                #if canImport(SwiftUI, _version: 8.0.85.27)
                if #available(iOS 27.1, macOS 27.1, *) {
                    ArrangementView {
                        editor
                    } secondary: {
                        inspector
                    }.arrangementViewStyle(.split)
                } else {
                    fallback(width: geometry.size.width)
                }
                #else
                fallback(width: geometry.size.width)
                #endif
            }.navigationTitle("Workspace")
        }
    }
    private func fallback(width: CGFloat) -> some View {
        let layout = width >= 640 ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        return layout {
            editor
            inspector
        }
    }
    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Draft").tw("text-lg font-semibold")
                TextEditor(text: $draft)
                    .scrollContentBackground(.hidden)
                    .font(monospaced ? .system(.body, design: .monospaced) : .body)
                    .accessibilityLabel("Arrangement draft")
                    .tw("min-h-[240] p-3 border rounded-lg bg-surface")
            }.tw("p-6 w-full")
        }.scrollBounceBehavior(.basedOnSize).tw("w-full h-full bg-background")
    }
    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Inspector").tw("text-lg font-semibold")
                Toggle("Monospaced font", isOn: $monospaced).toggleStyle(.tw("switch", base: .switch))
                Text("SwiftUI places these panes around active folds. The editor state belongs to this screen.")
                    .tw("text-sm text-mutedForeground")
            }.tw("p-6 w-full")
        }.tw("w-full h-full bg-surface")
    }
}
