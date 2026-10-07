import SwiftUI
import SwiftCN

struct NativeDrawerExample: View {
    @State private var nativeOpen = false
    @State private var convenienceOpen = false
    @State private var detent = PresentationDetent.height(260)
    @State private var preventDismissal = false
    @State private var dismissals = 0
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Open caller-owned sheet") { nativeOpen = true }
                .buttonStyle(.tw("button-outline"))
                .sheet(isPresented: $nativeOpen, onDismiss: didDismiss) {
                    ScrollView {
                        CNDrawerContent {
                            CNDialogTitle("Activity")
                            Text("The content uses a recipe. This sheet owns its configuration.")
                                .tw("text-sm text-mutedForeground")
                            Toggle("Prevent swipe dismissal", isOn: $preventDismissal)
                                .toggleStyle(.tw("switch", base: .switch))
                            Button("Expand") { withAnimation { detent = .large } }
                                .buttonStyle(.tw("button-secondary"))
                            Button("Done") { nativeOpen = false }
                                .buttonStyle(.tw("button-outline"))
                        }
                    }
                    .presentationDetents([.height(260), .large], selection: $detent)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(preventDismissal)
                    .presentationBackground(theme.color(.surface, scheme: scheme))
                    .preferredColorScheme(scheme)
                    #if os(macOS)
                        .frame(minWidth: 360, minHeight: 320)
                    #endif
                }
            CNDrawer(isPresented: $convenienceOpen, detents: [.height(260), .large],
                     selection: $detent, onDismiss: didDismiss) {
                CNDialogTitle("Convenience drawer")
                Text("The same content part, with native scrolling and presentation defaults.")
                    .tw("text-sm text-mutedForeground")
                Button("Expand") { withAnimation { detent = .large } }
                    .buttonStyle(.tw("button-secondary"))
                CNDialogClose()
            } label: { Text("Open convenience drawer") }
            Text("Dismissed \(dismissals) times").tw("text-sm text-mutedForeground")
        }
    }
    private func didDismiss() { dismissals += 1 }
}
