import SwiftUI

/// A stable option value is shared by selectors, commands, and questionnaire choices.
public struct CNOption<ID: Hashable & Sendable>: Identifiable, Hashable, Sendable {
    public let id: ID
    public var title: String
    public var detail: String?
    public var systemImage: String?
    public var isDisabled: Bool
    public init(_ id: ID, title: String, detail: String? = nil, systemImage: String? = nil, isDisabled: Bool = false) {
        self.id = id; self.title = title; self.detail = detail; self.systemImage = systemImage; self.isDisabled = isDisabled
    }
}


/// Public context keeps copied and imported dropdown parts interoperable.
public struct CNDropdownMenuContext {
    public var focusedID: FocusState<UUID?>.Binding?
    public var dismiss: () -> Void
    public var navigate: (KeyEquivalent) -> KeyPress.Result
    public init(focusedID: FocusState<UUID?>.Binding? = nil, dismiss: @escaping () -> Void = {},
                navigate: @escaping (KeyEquivalent) -> KeyPress.Result = { _ in .ignored }) {
        self.focusedID = focusedID; self.dismiss = dismiss; self.navigate = navigate
    }
}
private struct CNDropdownMenuContextKey: EnvironmentKey {
    static var defaultValue: CNDropdownMenuContext { .init() }
}
extension EnvironmentValues {
    public var cnDropdownMenuContext: CNDropdownMenuContext {
        get { self[CNDropdownMenuContextKey.self] }
        set { self[CNDropdownMenuContextKey.self] = newValue }
    }
}
