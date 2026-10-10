import SwiftUI
import SwiftCN

struct NativeSurfacesExample: View {
    private enum Tool: String, CaseIterable { case pencil, highlighter, eraser }
    @State private var appearance = TWAppearance.automatic
    @State private var tool = Tool.pencil
    @State private var expanded = false
    @State private var shares = 0
    @State private var sheetOpen = false
    @State private var note = ""
    @Namespace private var surfaces

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Appearance", selection: $appearance) {
                Text("Automatic").tag(TWAppearance.automatic)
                Text("Glass").tag(TWAppearance.glass)
                Text("Solid").tag(TWAppearance.solid)
            }.pickerStyle(.segmented)
            HStack(spacing: 12) {
                Button("Share") { shares += 1 }
                    .buttonStyle(.twNative("glass px-1"))
                Button("Open note") { sheetOpen = true }
                    .buttonStyle(.twNative("glass-prominent px-2 font-semibold"))
            }
            TWSurfaceGroup(spacing: 12) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(Tool.allCases, id: \.self) { item in
                            Button { tool = item } label: {
                                Image(systemName: item.rawValue).tw("p-2")
                                    .foregroundStyle(tool == item ? Color.accentColor : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.rawValue.capitalized)
                            .accessibilityAddTraits(tool == item ? .isSelected : [])
                        }
                        Button { withAnimation(.smooth) { expanded.toggle() } } label: {
                            Image(systemName: expanded ? "chevron.left" : "ellipsis").tw("p-2")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(expanded ? "Fewer tools" : "More tools")
                    }
                    .tw("px-2 py-1 surface-floating glass-interactive")
                    .twSurfaceID("tools", in: surfaces)
                    if expanded {
                        Button { tool = .pencil } label: { Image(systemName: "arrow.uturn.backward").tw("p-2") }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reset tool")
                            .tw("p-1 surface-floating glass-interactive")
                            .twSurfaceID("reset", in: surfaces)
                    }
                }
            }
            .tw("p-6 rounded-lg")
            .background(LinearGradient(colors: [.orange, .pink, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .rect(cornerRadius: 12))
            Text("Tool: \(tool.rawValue) · Shared \(shares) times").tw("text-sm text-mutedForeground")
        }
        .twAppearance(appearance)
        .sheet(isPresented: $sheetOpen) {
            ScrollView {
                CNDrawerContent {
                    CNDialogTitle("Note")
                    TextField("Write a note", text: $note)
                        .textFieldStyle(.tw("input"))
                    Button("Done") { sheetOpen = false }
                        .buttonStyle(.twNative("glass-prominent"))
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .twPresentationSurface()
            .twAppearance(appearance)
            #if os(macOS)
                .frame(minWidth: 360, minHeight: 280)
            #endif
        }
    }
}
