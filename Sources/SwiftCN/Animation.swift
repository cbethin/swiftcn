import SwiftUI

/// A native animation preset. Factories receive the duration selected by the style, in seconds.
public struct TWAnimation: Sendable {
    private let makeAnimation: @Sendable (TimeInterval) -> Animation?

    /// Use an exact native animation. Duration utilities do not retime this fixed preset.
    public init(_ animation: Animation) { makeAnimation = { _ in animation } }

    /// Define a native preset that responds to duration utilities.
    public init(_ makeAnimation: @escaping @Sendable (TimeInterval) -> Animation) {
        self.makeAnimation = makeAnimation
    }

    private init(optional makeAnimation: @escaping @Sendable (TimeInterval) -> Animation?) {
        self.makeAnimation = makeAnimation
    }

    public static let none = Self(optional: { _ in nil })
    public static let linear = Self { .linear(duration: $0) }
    public static let easeIn = Self { .easeIn(duration: $0) }
    public static let easeOut = Self { .easeOut(duration: $0) }
    public static let easeInOut = Self { .easeInOut(duration: $0) }
    public static let spring = Self { .spring(duration: $0) }
    public static let smooth = Self { .smooth(duration: $0) }
    public static let snappy = Self { .snappy(duration: $0) }
    public static let bouncy = Self { .bouncy(duration: $0) }

    static let defaults: [String: Self] = [
        "none": .none, "linear": .linear, "ease-in": .easeIn, "ease-out": .easeOut,
        "ease-in-out": .easeInOut, "spring": .spring, "smooth": .smooth,
        "snappy": .snappy, "bouncy": .bouncy
    ]

    func resolve(duration: TimeInterval, delay: TimeInterval) -> Animation? {
        makeAnimation(duration)?.delay(delay)
    }
}

struct TWResolvedMotion {
    var preset: TWAnimation?
    var duration: TimeInterval = 0.3
    var delay: TimeInterval = 0

    func update(_ transaction: inout Transaction, reduceMotion: Bool) {
        guard let preset, !transaction.disablesAnimations else { return }
        transaction.animation = reduceMotion ? nil : preset.resolve(duration: duration, delay: delay)
    }
}
