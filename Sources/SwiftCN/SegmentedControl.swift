import SwiftUI

/// A controlled single-selection group. Its selection never owns or recreates the selected content.
public struct CNSegmentedControl<Selection: Hashable, Content: View>: View {
    @Binding private var selection: Selection
    private let classes: TWClasses
    private let animated: Bool
    private let content: Content
    @Namespace private var indicator
    @FocusState private var focused: AnyHashable?
    @State private var segments: [CNSegmentDescriptor] = []
    @Environment(\.layoutDirection) private var direction
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(selection: Binding<Selection>, classes: TWClasses = "", animated: Bool = false,
                @ViewBuilder content: () -> Content) {
        _selection = selection; self.classes = classes; self.animated = animated; self.content = content()
    }

    public var body: some View {
        let selected = AnyHashable(selection)
        let enabled = segments.filter { $0.enabled }
        HStack(spacing: 2) { content }
            .tw(cn("segmented", classes))
            .environment(\.cnSegmentedContext, CNSegmentedContext(
                selection: selected,
                tabStop: enabled.contains { $0.id == selected } ? selected : enabled.first?.id,
                focused: $focused, indicator: indicator,
                accepts: { $0.base is Selection },
                select: { id in
                    if let value = id.base as? Selection { selection = value; focused = id }
                },
                navigate: navigate))
            .onPreferenceChange(CNSegmentOrder.self) { segments = $0 }
            .animation(animated && !reduceMotion ? .snappy(duration: 0.18) : nil, value: selection)
            .accessibilityElement(children: .contain)
    }

    private func navigate(from id: AnyHashable, key: KeyEquivalent) -> KeyPress.Result {
        let enabled = segments.filter { $0.enabled && $0.id.base is Selection }
        guard !enabled.isEmpty else { return .ignored }
        let forward: Bool
        switch key {
        case .rightArrow: forward = direction == .leftToRight
        case .leftArrow: forward = direction == .rightToLeft
        case .downArrow: forward = true
        case .upArrow: forward = false
        default: return .ignored
        }
        let current = enabled.firstIndex { $0.id == id } ?? (forward ? enabled.count - 1 : 0)
        let next = enabled[(current + (forward ? 1 : enabled.count - 1)) % enabled.count].id
        guard let value = next.base as? Selection else { return .ignored }
        selection = value
        focused = next
        return .handled
    }
}

/// A segment accepts any label view. Use native `.disabled` and accessibility modifiers on this part.
public struct CNSegment<Value: Hashable, Label: View>: View {
    private let value: Value
    private let classes: TWClasses
    private let label: Label
    @Environment(\.cnSegmentedContext) private var context
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var fallbackFocus: AnyHashable?
    @Namespace private var fallbackIndicator

    public init(_ value: Value, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        self.value = value; self.classes = classes; self.label = label()
    }

    public init(_ value: Value, title: LocalizedStringKey, classes: TWClasses = "") where Label == Text {
        self.init(value, classes: classes) { Text(title) }
    }

    public var body: some View {
        let id = AnyHashable(value)
        let selected = context?.selection == id
        let enabled = isEnabled && (context?.accepts(id) ?? false)
        let focus = context?.focused ?? $fallbackFocus
        Button { context?.select(id) } label: { label }
            .buttonStyle(.tw(cn("segmented-item", classes),
                             state: .init(isSelected: selected, isFocused: focus.wrappedValue == id)))
            .background {
                if selected {
                    Color.clear.tw("segmented-indicator", state: .init(isDisabled: !enabled))
                        .matchedGeometryEffect(id: "selection", in: context?.indicator ?? fallbackIndicator)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .focusable(enabled && (context?.tabStop == id))
            .focusEffectDisabled()
            .focused(focus, equals: id)
            .disabled(!enabled)
            .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
                context?.navigate(id, press.key) ?? .ignored
            }
            .preference(key: CNSegmentOrder.self, value: [CNSegmentDescriptor(id: id, enabled: enabled)])
            .accessibilityValue(selected ? Text("Selected") : Text("Not selected"))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

