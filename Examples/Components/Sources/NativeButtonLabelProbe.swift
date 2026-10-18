#if DEBUG
import SwiftUI
import SwiftCN

/// UI tests measure plain SwiftUI button labels beneath the gallery's styled ancestors.
struct NativeButtonLabelProbe: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button("Bordered label") {}
                .buttonStyle(.borderedProminent)
            if #available(iOS 26, macOS 26, *) {
                Button("Glass label") {}
                    .buttonStyle(.glassProminent)
            }
            // Text classes that are not colors must leave the inherited foreground alone.
            Button("Nested label") {}
                .buttonStyle(.borderedProminent)
                .tw("p-2 rounded-lg bg-muted text-center font-semibold hover:bg-accent")
            // An explicit text color still reaches native labels, as .foregroundStyle does.
            Button("Explicit label") {}
                .buttonStyle(.borderedProminent)
                .tw("text-foreground")
        }
        .tw("p-4 bg-background")
    }
}
#if os(macOS)
/// A real scene verifies that the native focus environment reaches direct style adapters.
struct NativeButtonFocusProbe: View {
    @FocusState private var focused: Bool
    var body: some View {
        HStack {
            Button("Focus styled button") { focused = true }
            Button("Styled focus target") {}
                .buttonStyle(.tw("button-primary bg-[#ff0000] focus:bg-[#00ff00]"))
                .focused($focused)
        }
    }
}
#endif
#endif
