import SwiftUI
import SwiftCN

private struct DemoMotionEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Static image exports disable demo effects while retaining their resting appearance.
    var demoMotionEnabled: Bool {
        get { self[DemoMotionEnabledKey.self] }
        set { self[DemoMotionEnabledKey.self] = newValue }
    }
}

struct DemoMotion: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.demoMotionEnabled) private var enabled
    var isEnabled: Bool { enabled && !reduceMotion }
    var soft: Animation? { isEnabled ? .smooth(duration: 0.24) : nil }
    var feedback: Animation? { isEnabled ? .spring(duration: 0.2, bounce: 0.12) : nil }
}

extension View {
    func demoEntrance(delay: Double = 0) -> some View { modifier(DemoEntrance(delay: delay)) }
    func demoNumber(_ value: Int) -> some View { modifier(DemoNumber(value: value)) }
    func demoSymbolBounce<Value: Equatable>(_ value: Value, speed: Double = 1.5, enabled: Bool = true) -> some View {
        modifier(DemoSymbolBounce(value: value, speed: speed, enabled: enabled))
    }
}

private struct DemoSymbolBounce<Value: Equatable>: ViewModifier {
    let value: Value
    let speed: Double
    let enabled: Bool
    private var motion = DemoMotion()

    @ViewBuilder func body(content: Content) -> some View {
        if enabled && motion.isEnabled {
            content.symbolEffect(.bounce, options: .speed(speed), value: value)
        } else {
            // On macOS 15, removing an installed effect can stop the parent's layout animation.
            content
        }
    }
}

private struct DemoEntrance: ViewModifier {
    let delay: Double
    private var motion = DemoMotion()
    @State private var appeared = false

    init(delay: Double) { self.delay = delay }

    func body(content: Content) -> some View {
        content
            .opacity(appeared || !motion.isEnabled ? 1 : 0)
            .offset(y: appeared || !motion.isEnabled ? 0 : 6)
            .animation(motion.soft?.delay(delay), value: appeared)
            .onAppear { appeared = true }
            .onDisappear { appeared = false }
    }
}

private struct DemoNumber: ViewModifier {
    let value: Int
    private var motion = DemoMotion()

    init(value: Int) { self.value = value }

    func body(content: Content) -> some View {
        content
            .monospacedDigit()
            .contentTransition(motion.isEnabled ? .numericText(value: Double(value)) : .identity)
            .animation(motion.soft, value: value)
    }
}

/// The native button configuration still supplies press state and activation.
struct DemoButtonStyle: ButtonStyle {
    let base: TWButtonStyle
    var feedbackEnabled = true

    func makeBody(configuration: Configuration) -> some View {
        DemoButtonBody(base: base, configuration: configuration, feedbackEnabled: feedbackEnabled)
    }
}

private struct DemoButtonBody: View {
    let base: TWButtonStyle
    let configuration: ButtonStyleConfiguration
    let feedbackEnabled: Bool
    private var motion = DemoMotion()
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovered = false

    init(base: TWButtonStyle, configuration: ButtonStyleConfiguration, feedbackEnabled: Bool) {
        self.base = base
        self.configuration = configuration
        self.feedbackEnabled = feedbackEnabled
    }

    private var moves: Bool { motion.isEnabled && isEnabled && feedbackEnabled }

    var body: some View {
        base.makeBody(configuration: configuration)
            .scaleEffect(moves ? (configuration.isPressed ? 0.98 : hovered ? 1.008 : 1) : 1)
            .offset(y: moves && hovered && !configuration.isPressed ? -0.75 : 0)
            .animation(moves ? motion.feedback : nil, value: configuration.isPressed)
            .animation(moves ? motion.soft : nil, value: hovered)
            .onHover { hovered = $0 }
    }
}

extension ButtonStyle where Self == DemoButtonStyle {
    static func demo(_ classes: String, feedback: Bool = true) -> DemoButtonStyle {
        DemoButtonStyle(base: TWButtonStyle(classes), feedbackEnabled: feedback)
    }

    static func demo(_ styles: TWStyle...) -> DemoButtonStyle {
        DemoButtonStyle(base: TWButtonStyle(TWStyle(styles)))
    }
}
