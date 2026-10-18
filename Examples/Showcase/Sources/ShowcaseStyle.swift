import SwiftUI
import SwiftCN

enum DemoApp: String, Identifiable, CaseIterable {
    case daylight, ledger, fieldnotes, roam
    var id: String { rawValue }
    var title: String { switch self { case .daylight: "Daylight"; case .ledger: "Ledger"; case .fieldnotes: "Fieldnotes"; case .roam: "Roam" } }
    var subtitle: String { switch self { case .daylight: "A little less busy."; case .ledger: "Money, made clear."; case .fieldnotes: "Keep the little things."; case .roam: "Go somewhere good." } }
    var symbol: String { switch self { case .daylight: "sun.max"; case .ledger: "chart.bar.xaxis"; case .fieldnotes: "book.closed"; case .roam: "mountain.2" } }
    var accent: Color { switch self { case .daylight: Color(red: 0.66, green: 0.36, blue: 0.17); case .ledger: Color(red: 0.17, green: 0.43, blue: 0.34); case .fieldnotes: Color(red: 0.44, green: 0.35, blue: 0.62); case .roam: Color(red: 0.20, green: 0.42, blue: 0.59) } }
    var lightAccent: Color {
        switch self {
        case .daylight: Color(red: 0.92, green: 0.66, blue: 0.43)
        case .ledger: Color(red: 0.50, green: 0.78, blue: 0.64)
        case .fieldnotes: Color(red: 0.72, green: 0.63, blue: 0.87)
        case .roam: Color(red: 0.51, green: 0.74, blue: 0.88)
        }
    }
    var theme: TWTheme {
        TWTheme(colors: [
            .background: .init(light: Color(red: 0.98, green: 0.97, blue: 0.95), dark: Color(red: 0.085, green: 0.09, blue: 0.10)),
            .primary: .init(light: accent, dark: lightAccent),
            .onPrimary: .init(light: .white, dark: Color(white: 0.08)),
            .accent: .init(light: accent.opacity(0.09), dark: accent.opacity(0.22)),
            .onAccent: .init(light: accent, dark: lightAccent),
            .border: .init(light: Color(white: 0.89), dark: Color(white: 0.22))
        ])
    }
}

struct Page<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { content }
                .frame(maxWidth: 920, alignment: .leading).tw("p-6 w-full")
                .frame(maxWidth: .infinity)
        }.scrollDismissesKeyboard(.interactively)
            .background {
                Color.clear.tw("bg-background").ignoresSafeArea(.container)
            }
    }
}
struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased()).tracking(2).tw("text-xs font-semibold text-primary")
            Text(title).font(.system(.largeTitle, design: .serif)).tw("font-semibold text-foreground")
                .accessibilityAddTraits(.isHeader)
            Text(subtitle).tw("text-sm text-mutedForeground")
        }.frame(maxWidth: .infinity, alignment: .leading).tw("w-full py-2")
    }
}
struct Surface<Content: View>: View {
    var classes: TWClasses = ""
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }.tw(cn("p-5 w-full bg-surface rounded-[24] border", classes))
    }
}
struct SectionHeading: View {
    let title: String
    var detail: String = ""
    var body: some View {
        HStack {
            Text(title).tw("text-lg font-semibold").accessibilityAddTraits(.isHeader)
            Spacer()
            Text(detail).tw("text-xs text-mutedForeground")
        }
    }
}
struct EmptyMessage: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).tw("text-2xl text-primary")
            Text(title).tw("font-semibold")
            Text(message).multilineTextAlignment(.center).tw("text-sm text-mutedForeground")
        }.tw("p-8 w-full bg-surface rounded-[24] border")
    }
}
struct DemoToolbar: ViewModifier {
    let app: DemoApp
    let exit: () -> Void
    func body(content: Content) -> some View {
        content.navigationTitle(app.title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CNButton(variant: .ghost, size: .icon, action: exit) { Image(systemName: "square.grid.2x2") }
                        .accessibilityLabel("All apps").accessibilityIdentifier("all-apps")
                }
            }
    }
}
struct EditorSheet<Content: View>: View {
    let title: String
    let canSave: Bool
    let save: () -> Bool
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Page { content }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if save() { dismiss() }
                        }.disabled(!canSave).accessibilityIdentifier("save-editor")
                    }
                }
        }.presentationDetents([.large]).presentationDragIndicator(.visible)
    }
}
func money(_ cents: Int) -> String { (Double(cents) / 100).formatted(.currency(code: "USD")) }

// Keep native List selection and navigation, with SwiftCN card surfaces.
extension View {
    func collectionRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
    func collectionStyle() -> some View {
        listStyle(.plain).scrollContentBackground(.hidden)
            .background { Color.clear.tw("bg-background").ignoresSafeArea(.container) }
    }
}
