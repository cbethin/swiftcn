import SwiftUI
import SwiftCN

public struct CNToast: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var message: String?
    /// Nil keeps the toast until the user dismisses it. Seconds must be finite and positive.
    public var duration: TimeInterval?
    public init(id: UUID = UUID(), title: String, message: String? = nil, duration: TimeInterval? = 5) {
        precondition(duration == nil || (duration!.isFinite && duration! > 0))
        self.id = id; self.title = title; self.message = message; self.duration = duration
    }
}
/// Per-window state, never a global notification singleton. Replacement cancels the old deadline.
public struct CNToastHost<Content: View>: View {
    @Binding private var toast: CNToast?
    private let classes: TWClasses
    private let content: Content
    public init(toast: Binding<CNToast?>, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        _toast = toast; self.classes = classes; self.content = content()
    }
    public var body: some View {
        content.overlay(alignment: .bottomTrailing) {
            if let current = toast {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(current.title).tw("text-sm font-semibold")
                        if let message = current.message { Text(message).tw("text-sm text-mutedForeground") }
                    }
                    CNButton(variant: .ghost, size: .icon, action: { dismiss(current.id) }) { Image(systemName: "xmark") }
                        .accessibilityLabel("Dismiss notification")
                }.tw(cn("toast max-w-[360]", classes)).accessibilityElement(children: .contain)
                    .task(id: current) {
                        guard let seconds = current.duration, seconds.isFinite, seconds > 0 else { return }
                        do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
                        guard !Task.isCancelled else { return }
                        dismiss(current.id)
                    }
            }
        }
    }
    private func dismiss(_ id: UUID) { if toast?.id == id { toast = nil } }
}
