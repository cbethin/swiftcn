import SwiftUI
import SwiftCN

/// Opening and removal are explicit actions. This view never accesses file contents on its own.
public struct CNAttachment<Preview: View>: View {
    private let url: URL
    private let title: String
    private let detail: String?
    private let progress: Double?
    private let onRemove: (() -> Void)?
    private let classes: TWClasses
    private let preview: Preview
    public init(url: URL, title: String, detail: String? = nil, progress: Double? = nil, classes: TWClasses = "",
                onRemove: (() -> Void)? = nil, @ViewBuilder preview: () -> Preview) {
        self.url = url; self.title = title; self.detail = detail; self.progress = progress
        self.classes = classes; self.onRemove = onRemove; self.preview = preview()
    }
    public init(url: URL, title: String, detail: String? = nil, progress: Double? = nil, classes: TWClasses = "",
                onRemove: (() -> Void)? = nil) where Preview == Image {
        self.init(url: url, title: title, detail: detail, progress: progress, classes: classes, onRemove: onRemove) {
            Image(systemName: "doc")
        }
    }
    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            preview.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Link(title, destination: url).buttonStyle(.tw("button-link px-0"))
                if let detail { Text(detail).tw("text-xs text-mutedForeground") }
                if let progress { CNProgress("Upload progress", value: progress) }
            }
            if let onRemove {
                CNButton(variant: .ghost, size: .icon, action: onRemove) { Image(systemName: "xmark") }
                    .accessibilityLabel("Remove \(title)")
            }
        }.tw(cn("attachment", classes))
    }
}
