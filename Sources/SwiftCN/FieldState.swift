import SwiftUI

extension EnvironmentValues {
    /// Shared by imported and locally copied field parts and native control styles.
    @Entry public var twFieldInvalid: Bool = false
    /// A group shares one native editor's focus with its surrounding decoration.
    @Entry public var twInputGroupFocus: FocusState<Bool>.Binding? = nil
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
