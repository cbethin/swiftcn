import SwiftUI

/// Dimensions for a styled control. A nil radius inherits the theme's medium radius.
public struct TWControlMetrics: Sendable {
    public var minHeight: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    public var iconWidth: CGFloat
    public var radius: CGFloat?

    public init(minHeight: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat,
                iconWidth: CGFloat? = nil, radius: CGFloat? = nil) {
        self.minHeight = minHeight; self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding; self.iconWidth = iconWidth ?? minHeight; self.radius = radius
        validate()
    }

    func validate() {
        precondition([minHeight, horizontalPadding, verticalPadding, iconWidth, radius ?? 0].allSatisfy { $0.isFinite && $0 >= 0 },
                     "Control dimensions must be finite and nonnegative.")
    }
}

/// Shared dimensions keyed by SwiftUI's existing control sizes.
public struct TWControlMetricsScale: Sendable {
    public var mini = TWControlMetrics(minHeight: 28, horizontalPadding: 8, verticalPadding: 2)
    public var small = TWControlMetrics(minHeight: 32, horizontalPadding: 12, verticalPadding: 4)
    public var regular = TWControlMetrics(minHeight: 36, horizontalPadding: 16, verticalPadding: 8)
    public var large = TWControlMetrics(minHeight: 40, horizontalPadding: 24, verticalPadding: 8)
    public var extraLarge = TWControlMetrics(minHeight: 48, horizontalPadding: 28, verticalPadding: 12)

    public init() {
        #if os(iOS)
        large.minHeight = 48; large.iconWidth = 48
        extraLarge.minHeight = 56; extraLarge.iconWidth = 56
        #endif
    }

    public subscript(size: ControlSize) -> TWControlMetrics {
        get {
            switch size {
            case .mini: mini
            case .small: small
            case .large: large
            case .extraLarge: extraLarge
            default: regular
            }
        }
        set {
            switch size {
            case .mini: mini = newValue
            case .small: small = newValue
            case .large: large = newValue
            case .extraLarge: extraLarge = newValue
            default: regular = newValue
            }
        }
    }
}

enum TWControlMetricRole: Equatable, Sendable { case button, input, row, icon }
