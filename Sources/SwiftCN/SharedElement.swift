import SwiftUI
import os

struct TWGroupScope {
    let name: String
    let namespace: Namespace.ID
    let state: TWState
}

struct TWGroupContext {
    var scopes: [TWGroupScope] = []

    func scope(named name: String?) -> TWGroupScope? {
        guard let name else { return scopes.last }
        return scopes.last { $0.name == name }
    }

    var states: [String: TWState] {
        var values: [String: TWState] = [:]
        for scope in scopes { values[scope.name] = scope.state }
        if let nearest = scopes.last { values[""] = nearest.state }
        return values
    }
}

extension EnvironmentValues {
    @Entry var twGroups: TWGroupContext = TWGroupContext()
}

struct TWClassSharedElementModifier: ViewModifier {
    let appearance: TWResolvedStyle
    let groups: TWGroupContext

    @ViewBuilder func body(content: Content) -> some View {
        if let id = appearance.sharedID {
            if let scope = groups.scope(named: appearance.sharedGroup) {
                content.twShared(id, in: scope.namespace,
                    properties: properties, isSource: appearance.sharedSource)
            } else {
                content.onAppear {
                    Logger(subsystem: "swiftcn", category: "groups")
                        .error("Shared element \(id, privacy: .public) needs an ancestor group")
                }
            }
        } else {
            content
        }
    }

    private var properties: MatchedGeometryProperties {
        switch appearance.sharedProperties {
        case .frame: .frame
        case .position: .position
        case .size: .size
        }
    }
}

extension View {
    /// Pair native geometry within an application-owned namespace.
    /// Apply before a fixed frame to interpolate size, or after styling to match a whole surface.
    public func twShared<ID: Hashable>(
        _ id: ID, in namespace: Namespace.ID,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center, isSource: Bool = true
    ) -> some View {
        modifier(TWSharedElementModifier(id: id, namespace: namespace,
            properties: properties, anchor: anchor, isSource: isSource))
    }
}

private struct TWSharedElementModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transaction { transaction in
            if reduceMotion { transaction.animation = nil }
        } body: { element in
            element.matchedGeometryEffect(id: id, in: namespace,
                properties: properties, anchor: anchor, isSource: isSource)
        }
    }
}
