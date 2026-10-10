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
#endif
