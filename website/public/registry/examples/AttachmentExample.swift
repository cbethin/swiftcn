import SwiftUI
import SwiftCN

struct AttachmentExample: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNAttachment(url: URL(string: "https://github.com/cbethin/swiftcn")!, title: "Design notes", detail: "Markdown · 12 KB")

        }
    }
}
