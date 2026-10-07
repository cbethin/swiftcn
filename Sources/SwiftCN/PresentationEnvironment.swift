import SwiftUI

extension EnvironmentValues {
    /// Copy public appearance and localization across a custom presentation boundary.
    /// Native focus dispatch and enabled state remain the receiving host's responsibility.
    public mutating func cnPresentationAppearance(from source: EnvironmentValues) {
        twTheme = source.twTheme
        twRules = source.twRules
        twGroups = source.twGroups
        twFieldInvalid = source.twFieldInvalid
        colorScheme = source.colorScheme
        dynamicTypeSize = source.dynamicTypeSize
        layoutDirection = source.layoutDirection
        font = source.font
        locale = source.locale
        calendar = source.calendar
        timeZone = source.timeZone
        controlSize = source.controlSize
        lineLimit = source.lineLimit
        multilineTextAlignment = source.multilineTextAlignment
        imageScale = source.imageScale
    }
}
