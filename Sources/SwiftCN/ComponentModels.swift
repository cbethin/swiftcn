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

