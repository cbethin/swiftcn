import SwiftUI

/// Decorate the native editor. The plain base prevents recursive style application.
@MainActor public struct TWTextFieldStyle: @preconcurrency TextFieldStyle {
    public var style: TWStyle
    public var state: TWState

    public init(_ classes: TWClasses = "input", state: TWState = TWState()) {
        style = .classes(classes)
        self.state = state
    }

    @_disfavoredOverload public init(_ classes: String, state: TWState = TWState()) {
        self.init(TWClasses(classes), state: state)
    }

    public init(_ first: TWStyle, _ styles: TWStyle..., state: TWState = TWState()) {
        style = TWStyle([first] + styles)
        self.state = state
    }

    // This is the conformance requirement exposed by SwiftUI's TextFieldStyle protocol.
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.textFieldStyle(.plain)
            .modifier(TWFieldControlModifier(style: style, state: state))
    }
}

extension TextFieldStyle where Self == TWTextFieldStyle {
    @MainActor public static func tw(_ classes: TWClasses = "input", state: TWState = TWState()) -> Self {
        Self(classes, state: state)
    }
    @_disfavoredOverload @MainActor public static func tw(_ classes: String, state: TWState = TWState()) -> Self {
        tw(TWClasses(classes), state: state)
    }
    @MainActor public static func tw(_ first: TWStyle, _ styles: TWStyle..., state: TWState = TWState()) -> Self {
        Self(TWStyle([first] + styles), state: state)
    }
}

/// Retain a native toggle style and its original binding and mixed-state configuration.
public struct TWToggleStyle<Base: ToggleStyle>: ToggleStyle {
    public var base: Base
    public var style: TWStyle
    public var state: TWState

    public init(_ classes: TWClasses = "toggle", base: Base, state: TWState = TWState()) {
        self.base = base
        style = .classes(classes)
        self.state = state
    }

    @_disfavoredOverload public init(_ classes: String, base: Base, state: TWState = TWState()) {
        self.init(TWClasses(classes), base: base, state: state)
    }

    public init(_ style: TWStyle, base: Base, state: TWState = TWState()) {
        self.base = base
        self.style = style
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration).toggleStyle(base)
            .modifier(TWFieldControlModifier(style: style, state: state))
    }
}

extension ToggleStyle where Self == TWToggleStyle<DefaultToggleStyle> {
    public static func tw(_ classes: TWClasses = "toggle", state: TWState = TWState()) -> Self {
        Self(classes, base: .automatic, state: state)
    }
    @_disfavoredOverload public static func tw(_ classes: String, state: TWState = TWState()) -> Self {
        tw(TWClasses(classes), state: state)
    }
    public static func tw(_ first: TWStyle, _ styles: TWStyle..., state: TWState = TWState()) -> Self {
        Self(TWStyle([first] + styles), base: .automatic, state: state)
    }
    public static func tw<Base: ToggleStyle>(_ classes: TWClasses = "toggle", base: Base,
                                             state: TWState = TWState()) -> TWToggleStyle<Base> {
        TWToggleStyle(classes, base: base, state: state)
    }
}

/// Decorate the result of a native label style without discarding its title or icon.
public struct TWLabelStyle<Base: LabelStyle>: LabelStyle {
    public var base: Base
    public var style: TWStyle
    public var state: TWState

    public init(_ classes: TWClasses = "label", base: Base, state: TWState = TWState()) {
        self.base = base
        style = .classes(classes)
        self.state = state
    }

    @_disfavoredOverload public init(_ classes: String, base: Base, state: TWState = TWState()) {
        self.init(TWClasses(classes), base: base, state: state)
    }

    public init(_ style: TWStyle, base: Base, state: TWState = TWState()) {
        self.base = base
        self.style = style
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        base.makeBody(configuration: configuration)
            .modifier(TWModifier(style: style, state: state))
    }
}

extension LabelStyle where Self == TWLabelStyle<DefaultLabelStyle> {
    public static func tw(_ classes: TWClasses = "label", state: TWState = TWState()) -> Self {
        Self(classes, base: .automatic, state: state)
    }
    @_disfavoredOverload public static func tw(_ classes: String, state: TWState = TWState()) -> Self {
        tw(TWClasses(classes), state: state)
    }
    public static func tw(_ first: TWStyle, _ styles: TWStyle..., state: TWState = TWState()) -> Self {
        Self(TWStyle([first] + styles), base: .automatic, state: state)
    }
    public static func tw<Base: LabelStyle>(_ classes: TWClasses = "label", base: Base,
                                            state: TWState = TWState()) -> TWLabelStyle<Base> {
        TWLabelStyle(classes, base: base, state: state)
    }
}
