import SwiftUI
import SwiftCN

public struct CNSwitch<Label: View>: View {
    @Binding private var isOn: Bool
    private let classes: TWClasses
    private let label: Label
    public init(isOn: Binding<Bool>, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        _isOn = isOn; self.classes = classes; self.label = label()
    }
    public init(_ title: LocalizedStringKey, isOn: Binding<Bool>, classes: TWClasses = "") where Label == Text {
        self.init(isOn: isOn, classes: classes) { Text(title) }
    }
    public var body: some View {
        Toggle(isOn: $isOn) { label }.toggleStyle(CNSwitchStyle(classes: classes)).cnControlUtilities()
    }
}
public struct CNCheckbox<Label: View>: View {
    @Binding private var isOn: Bool
    private let classes: TWClasses
    private let label: Label
    public init(isOn: Binding<Bool>, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        _isOn = isOn; self.classes = classes; self.label = label()
    }
    public init(_ title: LocalizedStringKey, isOn: Binding<Bool>, classes: TWClasses = "") where Label == Text {
        self.init(isOn: isOn, classes: classes) { Text(title) }
    }
    public var body: some View {
        Toggle(isOn: $isOn) { label }.toggleStyle(CNCheckboxStyle(classes: classes)).cnControlUtilities()
    }
}
/// A styled activation surface fills gaps around the native checkbox and its label.
public struct CNCheckboxStyle: ToggleStyle {
    private let classes: TWClasses
    public init(classes: TWClasses = "") { self.classes = classes }
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                #if os(macOS)
                Toggle(configuration).toggleStyle(.checkbox).labelsHidden().fixedSize()
                    .allowsHitTesting(false).focusable(false).accessibilityHidden(true)
                #else
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    .accessibilityHidden(true)
                #endif
                configuration.label
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.buttonStyle(CNToggleSurfaceStyle(classes: cn("checkbox", classes)))
            .accessibilityValue(configuration.isOn ? Text("Checked") : Text("Unchecked"))
            .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
            .cnControlUtilities()
    }
}
/// The native switch keeps its thumb gesture, keyboard handling, and accessibility.
public struct CNSwitchStyle: ToggleStyle {
    private let classes: TWClasses
    public init(classes: TWClasses = "") { self.classes = classes }
    public func makeBody(configuration: Configuration) -> some View {
        CNSwitchRow(configuration: configuration, classes: classes)
    }
}
private struct CNSwitchRow: View {
    let configuration: ToggleStyleConfiguration
    let classes: TWClasses
    @Namespace private var space
    @State private var indicatorFrame = CGRect.zero
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        HStack(spacing: 12) {
            configuration.label.allowsHitTesting(false).accessibilityHidden(true)
            Spacer(minLength: 0)
            Toggle(configuration).toggleStyle(.switch).labelsHidden().fixedSize()
                .background { GeometryReader { geometry in
                    Color.clear.preference(key: CNSwitchIndicatorFrame.self, value: geometry.frame(in: .named(space)))
                } }
        }.tw(cn("switch", classes)).contentShape(.interaction, Rectangle())
            .coordinateSpace(name: space)
            .onPreferenceChange(CNSwitchIndicatorFrame.self) { indicatorFrame = $0 }
            .simultaneousGesture(SpatialTapGesture(coordinateSpace: .named(space)).onEnded { value in
                // The system indicator handles its own tap or drag. Only the remaining row activates here.
                if isEnabled && !indicatorFrame.contains(value.location) { configuration.isOn.toggle() }
            })
            .cnControlUtilities()
    }
}
private struct CNSwitchIndicatorFrame: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
private struct CNToggleSurfaceStyle: ButtonStyle {
    let classes: TWClasses
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tw(classes, state: .init(isPressed: configuration.isPressed))
            .contentShape(.interaction, Rectangle())
    }
}
public struct CNToggle<Label: View>: View {
    @Binding private var isOn: Bool
    private let classes: TWClasses
    private let label: Label
    public init(isOn: Binding<Bool>, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        _isOn = isOn; self.classes = classes; self.label = label()
    }
    public init(_ title: LocalizedStringKey, isOn: Binding<Bool>, classes: TWClasses = "") where Label == Text {
        self.init(isOn: isOn, classes: classes) { Text(title) }
    }
    public var body: some View {
        Toggle(isOn: $isOn) { label }.toggleStyle(CNButtonToggleStyle(classes: classes)).cnControlUtilities()
    }
}

/// Toggle configuration retains its binding while the native Button owns activation.
public struct CNButtonToggleStyle: ToggleStyle {
    private let classes: TWClasses
    public init(classes: TWClasses = "") { self.classes = classes }
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: { configuration.label }
            .buttonStyle(.tw(cn("bezel-prominent rounded-md text-sm font-semibold", configuration.isOn ? "toggle-selected" : "toggle-unselected", classes)))
            .accessibilityValue(configuration.isOn ? Text("On") : Text("Off"))
            .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
public struct CNToggleGroup<ID: Hashable & Sendable>: View {
    private let options: [CNOption<ID>]
    @Binding private var selection: Set<ID>
    private let classes: TWClasses
    private let axis: Axis
    public init(_ options: [CNOption<ID>], selection: Binding<Set<ID>>, axis: Axis = .horizontal, classes: TWClasses = "") {
        self.options = options; _selection = selection; self.axis = axis; self.classes = classes
    }
    public var body: some View {
        CNButtonGroup(axis: axis, classes: classes) {
            ForEach(options) { option in
                CNToggle(isOn: Binding(get: { selection.contains(option.id) }, set: { on in
                    if on { selection.insert(option.id) } else { selection.remove(option.id) }
                })) { Text(option.title) }.disabled(option.isDisabled)
            }
        }
    }
}

public struct CNSelect<ID: Hashable & Sendable>: View {
    private let title: LocalizedStringKey
    private let options: [CNOption<ID>]
    @Binding private var selection: ID
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, options: [CNOption<ID>], selection: Binding<ID>, classes: TWClasses = "") {
        self.title = title; self.options = options; _selection = selection; self.classes = classes
    }
    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options) { option in Text(option.title).tag(option.id).disabled(option.isDisabled) }
        }.pickerStyle(.menu).tw(cn("select", classes)).cnControlUtilities()
    }
}
/// Uses automatic native picker presentation, including platform-specific keyboard behavior.
public struct CNNativeSelect<ID: Hashable & Sendable>: View {
    private let title: LocalizedStringKey
    private let options: [CNOption<ID>]
    @Binding private var selection: ID
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, options: [CNOption<ID>], selection: Binding<ID>, classes: TWClasses = "") {
        self.title = title; self.options = options; _selection = selection; self.classes = classes
    }
    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options) { option in Text(option.title).tag(option.id).disabled(option.isDisabled) }
        }.tw(cn("select", classes)).cnControlUtilities()
    }
}
/// Native single selection. The optional binding exposes an explicit empty choice.
public struct CNRadioGroup<ID: Hashable & Sendable>: View {
    private let title: LocalizedStringKey
    private let options: [CNOption<ID>]
    @Binding private var selection: ID?
    private let allowsEmpty: Bool
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, options: [CNOption<ID>], selection: Binding<ID>, classes: TWClasses = "") {
        self.title = title; self.options = options
        _selection = Binding(get: { selection.wrappedValue }, set: { if let value = $0 { selection.wrappedValue = value } })
        allowsEmpty = false; self.classes = classes
    }
    public init(_ title: LocalizedStringKey, options: [CNOption<ID>], selection: Binding<ID?>, classes: TWClasses = "") {
        self.title = title; self.options = options; _selection = selection; allowsEmpty = true; self.classes = classes
    }
    public var body: some View {
        let picker = Picker(title, selection: $selection) {
            if allowsEmpty { Text("Choose an option").tag(Optional<ID>.none) }
            ForEach(options) { option in Text(option.title).tag(Optional(option.id)).disabled(option.isDisabled) }
        }.tw(cn("radio-group", classes)).cnControlUtilities()
        #if os(macOS)
        picker.pickerStyle(.radioGroup)
        #else
        picker.pickerStyle(.inline)
        #endif
    }
}
