import SwiftUI

private struct CNLoadingPhaseKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}
extension EnvironmentValues {
    /// Nil uses the live native clock. A fixed phase makes previews and snapshots reproducible.
    public var cnLoadingPhase: Double? {
        get { self[CNLoadingPhaseKey.self] }
        set { self[CNLoadingPhaseKey.self] = newValue.map { $0.isFinite ? min(1, max(0, $0)) : 0 } }
    }
}
extension View {
    public func cnLoadingPhase(_ phase: Double?) -> some View { environment(\.cnLoadingPhase, phase) }
}

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
extension EnvironmentValues {
    @Entry public var cnDropdownMenuContext: CNDropdownMenuContext = .init()
}

/// Shared context lets copied sidebar parts compose with the imported root.
public struct CNSidebarContext {
    public var isCollapsed: Bool
    public var isCompact: Bool
    public var isPresented: Bool
    public var canToggle: Bool
    public var toggle: () -> Void
    public var dismiss: () -> Void
    public init(isCollapsed: Bool = false, isCompact: Bool = false, isPresented: Bool = true, canToggle: Bool = true,
                toggle: @escaping () -> Void = {}, dismiss: @escaping () -> Void = {}) {
        self.isCollapsed = isCollapsed; self.isCompact = isCompact; self.isPresented = isPresented
        self.canToggle = canToggle
        self.toggle = toggle; self.dismiss = dismiss
    }
}
extension EnvironmentValues {
    @Entry public var cnSidebarContext: CNSidebarContext = .init()
}

// One shared key keeps copied and imported presentation parts interoperable.
// A closure-valued entry stays explicit to avoid newer @Entry comparison warnings.
private struct CNPresentationDismissKey: EnvironmentKey {
    static var defaultValue: (() -> Void)? { nil }
}
extension EnvironmentValues {
    /// The active custom presentation's close action. Nil uses native dismissal.
    public var cnPresentationDismiss: (() -> Void)? {
        get { self[CNPresentationDismissKey.self] }
        set { self[CNPresentationDismissKey.self] = newValue }
    }
}

/// Shared context lets imported and locally copied segment parts compose.
public struct CNSegmentedContext {
    public let selection: AnyHashable
    public let tabStop: AnyHashable?
    public let focused: FocusState<AnyHashable?>.Binding
    public let indicator: Namespace.ID
    public let accepts: (AnyHashable) -> Bool
    public let select: (AnyHashable) -> Void
    public let navigate: (AnyHashable, KeyEquivalent) -> KeyPress.Result

    public init(selection: AnyHashable, tabStop: AnyHashable?, focused: FocusState<AnyHashable?>.Binding,
                indicator: Namespace.ID, accepts: @escaping (AnyHashable) -> Bool,
                select: @escaping (AnyHashable) -> Void,
                navigate: @escaping (AnyHashable, KeyEquivalent) -> KeyPress.Result) {
        self.selection = selection; self.tabStop = tabStop; self.focused = focused; self.indicator = indicator
        self.accepts = accepts; self.select = select; self.navigate = navigate
    }
}

extension EnvironmentValues {
    @Entry public var cnSegmentedContext: CNSegmentedContext? = nil
}

// Preference values stay on SwiftUI's UI thread; AnyHashable wraps the caller's stable selection values.
public struct CNSegmentDescriptor: Equatable, @unchecked Sendable {
    public let id: AnyHashable
    public let enabled: Bool
    public init(id: AnyHashable, enabled: Bool) { self.id = id; self.enabled = enabled }
}
public struct CNSegmentOrder: PreferenceKey {
    public static let defaultValue: [CNSegmentDescriptor] = []
    public static func reduce(value: inout [CNSegmentDescriptor], nextValue: () -> [CNSegmentDescriptor]) {
        value.append(contentsOf: nextValue())
    }
}
