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
        Toggle(isOn: $isOn) { label }.toggleStyle(.switch).tw(cn("switch", classes)).cnControlUtilities()
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
        #if os(macOS)
        Toggle(isOn: $isOn) { label }.toggleStyle(.checkbox).tw(cn("checkbox", classes)).cnControlUtilities()
        #else
        Toggle(isOn: $isOn) { label }.toggleStyle(CNCheckboxStyle()).tw(cn("checkbox", classes)).cnControlUtilities()
        #endif
    }
}
/// The iOS adaptation uses a native Toggle configuration and accessible Button activation.
public struct CNCheckboxStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square").accessibilityHidden(true)
                configuration.label
            }
        }.buttonStyle(.tw("button-ghost min-h-[44] px-0"))
            .accessibilityValue(configuration.isOn ? Text("Checked") : Text("Unchecked"))
            .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
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
        Toggle(isOn: $isOn) { label }.toggleStyle(.button)
            .tw(cn("toggle cn-tint-[primary]", classes)).cnControlUtilities()
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
