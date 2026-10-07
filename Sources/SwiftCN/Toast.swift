import SwiftUI
import Accessibility

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
/// Per-window notifications with stable, unique IDs. Append to show a stack, or use one optional toast.
public struct CNToastHost<Content: View>: View {
    @Environment(\.layoutDirection) private var direction
    @Binding private var toasts: [CNToast]
    @Binding private var boundExpansion: Bool
    private let usesLocalExpansion: Bool
    @State private var localExpansion = false
    @FocusState private var expansionFocused: Bool
    @AccessibilityFocusState private var expansionAccessible: Bool
    private let classes: TWClasses
    private let content: Content
    public init(toast: Binding<CNToast?>, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        _toasts = Binding(get: { toast.wrappedValue.map { [$0] } ?? [] },
                          set: { toast.wrappedValue = $0.first })
        _boundExpansion = .constant(false); usesLocalExpansion = true
        self.classes = classes; self.content = content()
    }
    /// The newest toast sits in front. Expand the deck to read and dismiss earlier messages.
    public init(toasts: Binding<[CNToast]>, isExpanded: Binding<Bool>? = nil,
                classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        _toasts = toasts; _boundExpansion = isExpanded ?? .constant(false); usesLocalExpansion = isExpanded == nil
        self.classes = classes; self.content = content()
    }
    private var expansion: Binding<Bool> { usesLocalExpansion ? $localExpansion : $boundExpansion }
    public var body: some View {
        let expanded = expansion.wrappedValue
        let layout = expanded ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 8)) : AnyLayout(CNToastDeckLayout())
        content.overlay(alignment: .bottomTrailing) {
            GeometryReader { geometry in
                let region = CNPlacementRegions.preferred(in: geometry.cnPlacementRegions(layoutDirection: direction),
                    near: CGPoint(x: direction == .leftToRight ? geometry.size.width : 0, y: geometry.size.height))
                VStack(alignment: .trailing, spacing: 8) {
                    ScrollView {
                        layout {
                            ForEach(Array(toasts.enumerated()), id: \.element.id) { index, current in
                                let depth = toasts.count - index - 1
                                CNToastCard(toast: current, classes: classes, concealed: !expanded && depth > 0,
                                            reading: expanded || expansionFocused || expansionAccessible, dismiss: dismiss)
                                    .scaleEffect(expanded ? 1 : 1 - CGFloat(min(depth, 2)) * 0.04, anchor: .bottom)
                                    .opacity(expanded || depth < 3 ? 1 : 0)
                                    .allowsHitTesting(expanded || depth == 0)
                                    .accessibilityHidden(!expanded && depth > 0)
                                    .zIndex(Double(index))
                            }
                        }
                        .tw("p-2")
                    }
                    .defaultScrollAnchor(.bottom)
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxHeight: max(0, region.height - (toasts.count > 1 ? expansionControlHeight + 8 : 0)))
                    .fixedSize(horizontal: false, vertical: true)
                    if toasts.count > 1 {
                        Button { expansion.wrappedValue.toggle() } label: {
                            Label(expanded ? "Collapse" : "\(toasts.count) notifications",
                                  systemImage: expanded ? "chevron.down" : "chevron.up")
                        }
                        .focusable().focusEffectDisabled().focused($expansionFocused)
                        .buttonStyle(.tw("button-ghost w-[160] min-h-[\(expansionControlHeight)] px-2 py-1 text-xs",
                                         state: .init(isFocused: expansionFocused)))
                        .accessibilityLabel(expanded ? "Collapse notifications" : "Show all \(toasts.count) notifications")
                        .accessibilityFocused($expansionAccessible)
                    }
                }
                .twAnimation(cn("feedback-motion", classes), value: CNToastPresentation(ids: toasts.map(\.id), expanded: expanded))
                .frame(maxWidth: min(360, region.width))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: region.width, height: region.height, alignment: .bottomTrailing)
                .position(x: region.midX, y: region.midY)
            }
            .allowsHitTesting(!toasts.isEmpty)
            .accessibilityHidden(toasts.isEmpty)
        }
        .onChange(of: toasts.count) { _, count in if count < 2 { expansion.wrappedValue = false } }
    }
    private var expansionControlHeight: CGFloat {
        #if os(iOS)
        44
        #else
        28
        #endif
    }
    // A deadline from an older render cannot remove an updated notification with the same ID.
    private func dismiss(_ toast: CNToast) { toasts.removeAll { $0 == toast } }
}

private struct CNToastPresentation: Equatable {
    let ids: [UUID]
    let expanded: Bool
}

/// One layout change preserves every card's identity and its countdown.
private struct CNToastDeckLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let front = subviews.last else { return .zero }
        let size = front.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: size.width, height: size.height + CGFloat(min(subviews.count - 1, 2)) * 8)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let height = max(0, bounds.height - CGFloat(min(max(0, subviews.count - 1), 2)) * 8)
        for index in subviews.indices {
            let depth = min(subviews.count - index - 1, 2)
            subviews[index].place(at: CGPoint(x: bounds.midX, y: bounds.maxY - CGFloat(depth) * 8),
                                 anchor: .bottom, proposal: ProposedViewSize(width: bounds.width, height: height))
        }
    }
}

/// The clock preserves remaining time through hover and focus, without polling or a shared timer.
struct CNToastLifetime {
    private(set) var remaining: Duration?
    private(set) var deadline: ContinuousClock.Instant?
    mutating func reset(duration: TimeInterval?, paused: Bool, at now: ContinuousClock.Instant) {
        remaining = duration.flatMap { $0.isFinite && $0 > 0 ? .seconds($0) : nil }
        deadline = paused ? nil : remaining.map { now.advanced(by: $0) }
    }
    mutating func pause(at now: ContinuousClock.Instant) {
        guard let deadline else { return }
        remaining = max(.zero, now.duration(to: deadline))
        self.deadline = nil
    }
    mutating func resume(at now: ContinuousClock.Instant) {
        guard deadline == nil, let remaining else { return }
        deadline = now.advanced(by: remaining)
    }
}

private enum CNToastFocus: Hashable { case message, dismiss }

private struct CNToastCard: View {
    let toast: CNToast
    let classes: TWClasses
    let concealed: Bool
    let reading: Bool
    let dismiss: (CNToast) -> Void
    @State private var lifetime = CNToastLifetime()
    @State private var hovered = false
    @FocusState private var closeFocused: Bool
    @AccessibilityFocusState private var accessibleFocus: CNToastFocus?
    private var paused: Bool { reading || hovered || closeFocused || accessibleFocus != nil }
    var body: some View {
        let deadline = lifetime.deadline
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title).tw("text-sm font-semibold")
                if let message = toast.message { Text(message).tw("text-sm text-mutedForeground") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityFocused($accessibleFocus, equals: .message)
            Button { dismiss(toast) } label: { Image(systemName: "xmark") }
                .accessibilityLabel("Dismiss notification: \(toast.title)")
                .focusable(!concealed).focusEffectDisabled()
                .focused($closeFocused)
                .buttonStyle(.tw(cn("button-ghost", CNButtonSize.icon.classes), state: .init(isFocused: closeFocused)))
                .accessibilityFocused($accessibleFocus, equals: .dismiss)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(concealed ? 0 : 1)
        .tw(cn("toast max-w-[360]", classes))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .accessibilityElement(children: .contain)
        .disabled(concealed)
        .onHover { hovered = $0 }
        .onChange(of: concealed) { _, concealed in
            if concealed { hovered = false; closeFocused = false; accessibleFocus = nil }
        }
        .onChange(of: toast, initial: true) { _, current in
            lifetime.reset(duration: current.duration, paused: paused, at: .now)
            AccessibilityNotification.Announcement([current.title, current.message].compactMap { $0 }.joined(separator: ". ")).post()
        }
        .onChange(of: paused) { _, paused in
            if paused { lifetime.pause(at: .now) } else { lifetime.resume(at: .now) }
        }
        .task(id: deadline) {
            guard let deadline else { return }
            do { try await ContinuousClock().sleep(until: deadline) } catch { return }
            guard !Task.isCancelled, lifetime.deadline == deadline else { return }
            dismiss(toast)
        }
    }
}
