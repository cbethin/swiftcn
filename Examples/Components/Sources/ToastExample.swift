import SwiftUI
import SwiftCN

struct ToastExample: View {
    @State private var toasts: [CNToast] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNToastHost(toasts: $toasts) {
                CNButton("Save changes", action: { toasts.append(CNToast(title: "Saved", message: "Your changes are up to date.")) })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }.tw("h-[180]")

        }
    }
}
