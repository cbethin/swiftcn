import SwiftUI
import SwiftCN

struct ToastExample: View {
    @State private var toast: CNToast? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNToastHost(toast: $toast) {
                CNButton("Save changes", action: { toast = CNToast(title: "Saved", message: "Your changes are up to date.") })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }.tw("h-[180]")

        }
    }
}
