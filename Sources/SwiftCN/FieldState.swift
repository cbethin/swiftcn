import SwiftUI

private struct TWFieldInvalidKey: EnvironmentKey {
    static let defaultValue = false
}
private struct TWInputGroupFocusKey: EnvironmentKey {
    static var defaultValue: FocusState<Bool>.Binding? { nil }
}

extension EnvironmentValues {
    /// Shared by imported and locally copied field parts and native control styles.
    public var twFieldInvalid: Bool {
        get { self[TWFieldInvalidKey.self] }
        set { self[TWFieldInvalidKey.self] = newValue }
    }
    /// A group shares one native editor's focus with its surrounding decoration.
    public var twInputGroupFocus: FocusState<Bool>.Binding? {
        get { self[TWInputGroupFocusKey.self] }
        set { self[TWInputGroupFocusKey.self] = newValue }
    }
}

public struct TWFieldControlModifier: ViewModifier {
    private let style: TWStyle
    private let state: TWState
    @Environment(\.twFieldInvalid) private var isInvalid

    public init(style: TWStyle, state: TWState = TWState()) {
        self.style = style
        self.state = state
    }

    public func body(content: Content) -> some View {
        content.tw([style, isInvalid ? .classes("field-invalid") : TWStyle()], state: state)
    }
}
