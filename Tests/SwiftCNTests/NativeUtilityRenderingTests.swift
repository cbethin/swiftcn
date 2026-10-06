#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Hosted native utilities", .serialized)
@MainActor
struct NativeUtilityRenderingTests {
    @Test(arguments: [false, true])
    func registeredFactoriesProduceTheNativePixels(dark: Bool) throws {
        let rules = TWGlobalRules(modifiers: [
            "glass": .view { view, active in view.background(active ? Color.blue : .clear) },
            "shift": .argument(default: CGFloat.zero, order: 1,
                parse: { argument, theme in argument.points.map { $0 * theme.spacingUnit } }) { view, distance in
                view.offset(x: distance)
            }
        ])
        let native = Text("Native modifier").tw("p-4").background(Color.blue).modifier(NativeShift(distance: 12))
        let registered = Text("Native modifier").tw("p-4 glass shift-[3]").twRules(rules)
        let expected = try render(native, dark: dark)
        let actual = try render(registered, dark: dark)
        #expect(actual.width == expected.width && actual.height == expected.height)
        #expect(try pixels(expected) == pixels(actual))
        let inactive = Text("Native modifier").tw("p-4").twRules(rules)
        #expect(try pixels(render(inactive, dark: dark)) == pixels(render(Text("Native modifier").tw("p-4"), dark: dark)))
        if let directory = ProcessInfo.processInfo.environment["SWIFTCN_NATIVE_ARTIFACTS"] {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            for (label, image) in [("native", expected), ("classes", actual)] {
                let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
                try data.write(to: URL(fileURLWithPath: directory)
                    .appendingPathComponent("modifiers-\(dark ? "dark" : "light")-\(label).png"))
            }
        }
    }

    @Test(arguments: [false, true], [false, true])
    func argumentChangesAndTagRemovalPreserveIdentityAndNativeMotion(disabledTransaction: Bool, transform: Bool) {
        let model = NativeUtilityModel()
        let identities = NativeIdentityRecorder()
        let samples = NativeMotionSamples()
        var rules = TWGlobalRules(animations: ["probe": TWAnimation(Animation(NativeMotionProbe(samples: samples)))], modifiers: [
            "glass": .view { view, active in view.background(active ? Color.blue : .clear) },
            "shift": .argument(default: "0") { argument, _ in argument.points.map { NativeShift(distance: $0) } }
        ])
        if transform {
            rules.modifiers["shift"] = .argument(default: CGFloat.zero,
                parse: { argument, _ in argument.points }) { view, distance in view.offset(x: distance) }
        }
        let view = NativeUtilityHarness(model: model, identities: identities, samples: samples)
            .twRules(rules)
        withHost(view) { host in
            #expect(samples.times.isEmpty)
            for phase in [1, 2, 0] {
                var transaction = Transaction()
                transaction.disablesAnimations = disabledTransaction
                withTransaction(transaction) { model.phase = phase }
                settle(host, seconds: NativeMotionProbe.duration + 0.3)
                #expect(Set(identities.values).count == 1)
                if identities.reduceMotion == true || disabledTransaction { #expect(samples.times.isEmpty) }
                else {
                    #expect(samples.times(for: phase).contains { $0 > 0 && $0 < NativeMotionProbe.duration },
                        "Phase \(phase), native samples: \(samples.recentSamples)")
                }
                samples.clear()
            }
            #expect(Set(identities.phases) == [0, 1, 2])
        }
    }

    @Test func registryAllowsNativeModifierFactoriesAndCallerAnimations() {
        let model = NativeUtilityModel()
        let identities = NativeIdentityRecorder()
        let samples = NativeMotionSamples()
        let rules = TWGlobalRules(modifiers: [
            "shift": .modifier { active, _ in
                NativeStatefulShift(distance: active ? 40 : 0, identities: identities)
            }
        ])
        let view = NativeUtilityHarness(model: model, identities: identities, callerAnimation: true).twRules(rules)
        withHost(view) { host in
            for phase in [1, 0] {
                withAnimation(Animation(NativeMotionProbe(samples: samples))) { model.phase = phase }
                settle(host, seconds: NativeMotionProbe.duration + 0.3)
                #expect(samples.times.contains { $0 > 0 && $0 < NativeMotionProbe.duration })
                #expect(Set(identities.values).count == 1)
                #expect(Set(identities.modifierValues).count == 1)
                samples.clear()
            }
        }
    }

    @Test(arguments: [false, true])
    func publicLiteralOverloadsRenderNativePayloads(dark: Bool) throws {
        let color = Color(red: 0.2, green: 0.6, blue: 0.8)
        let amount = CGFloat(7.5)
        let rules = TWGlobalRules(modifiers: [
            "tint": .value(default: Color.clear) { view, color in view.background(color) }
        ])
        let expected = Text("Typed").tw("p-[7.5]").background(color)
        let actual = Text("Typed").tw("p-[\(amount)] tint-[\(color)]").twRules(rules)
        #expect(try pixels(render(actual, dark: dark)) == pixels(render(expected, dark: dark)))
        let button = Button {} label: { Text("Typed") }
            .buttonStyle(.tw("p-[\(amount)] tint-[\(color)]")).twRules(rules)
        #expect(try pixels(render(button, dark: dark)) == pixels(render(expected, dark: dark)))
    }

    @Test(arguments: [false, true])
    func publicInterpolationAnimatesNativeState(subtree: Bool) {
        let model = NativeUtilityModel()
        let identities = NativeIdentityRecorder()
        let samples = NativeMotionSamples()
        let animation = Animation(NativeMotionProbe(samples: samples))
        let rules = TWGlobalRules(modifiers: [
            "shift": .value(default: CGFloat.zero) { view, distance in view.offset(x: distance) }
        ])
        let view = TypedMotionHarness(model: model, identities: identities, animation: animation, subtree: subtree)
            .twRules(rules)
        withHost(view) { host in
            for phase in [1, 2, 0] {
                model.phase = phase
                settle(host, seconds: NativeMotionProbe.duration + 0.3)
                #expect(Set(identities.values).count == 1)
                if identities.reduceMotion == true { #expect(samples.times.isEmpty) }
                else { #expect(samples.times.contains { $0 > 0 && $0 < NativeMotionProbe.duration }) }
                samples.clear()
            }
        }
    }

    private func render<V: View>(_ view: V, dark: Bool) throws -> CGImage {
        let renderer = ImageRenderer(content: view.foregroundStyle(Color.primary).environment(\.colorScheme, dark ? .dark : .light))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    private func pixels(_ image: CGImage) throws -> Data {
        let context = try #require(CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Data(bytes: try #require(context.data), count: image.width * image.height * 4)
    }

    private func withHost<V: View>(_ view: V, run: (NSHostingView<V>) -> Void) {
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 100)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        settle(host, seconds: 0.1)
        run(host)
    }

    private func settle<V: View>(_ host: NSHostingView<V>, seconds: TimeInterval) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }
}

private struct NativeShift: ViewModifier {
    let distance: CGFloat
    func body(content: Content) -> some View { content.offset(x: distance) }
}

private struct NativeStatefulShift: ViewModifier {
    let distance: CGFloat
    let identities: NativeIdentityRecorder
    @State private var identity = UUID()
    func body(content: Content) -> some View {
        identities.modifierValues.append(identity)
        return content.offset(x: distance)
    }
}

@MainActor private final class NativeUtilityModel: ObservableObject { @Published var phase = 0 }
@MainActor private final class NativeIdentityRecorder {
    var values: [UUID] = []
    var phases: [Int] = []
    var reduceMotion: Bool?
    var modifierValues: [UUID] = []
}
private struct NativeUtilityHarness: View {
    @ObservedObject var model: NativeUtilityModel
    let identities: NativeIdentityRecorder
    var callerAnimation = false
    var samples: NativeMotionSamples? = nil
    var body: some View {
        NativeUtilityChild(phase: model.phase, identities: identities)
            .tw(cn {
                if callerAnimation {
                    if model.phase != 0 { "shift" }
                } else {
                    "animate-probe"
                    if model.phase != 0 { "glass shift-[\(model.phase * 40)]" }
                }
            }, value: model.phase)
            .twRules { rules in
                if let samples {
                    // Distinguish each transition from the previous probe's completed timeline.
                    rules.animations["probe"] = TWAnimation(Animation(NativeMotionProbe(samples: samples, generation: model.phase)))
                }
            }
    }
}
private struct TypedMotionHarness: View {
    @ObservedObject var model: NativeUtilityModel
    let identities: NativeIdentityRecorder
    let animation: Animation
    let subtree: Bool
    var body: some View {
        let distance = CGFloat(model.phase * 40)
        if subtree {
            NativeUtilityChild(phase: model.phase, identities: identities)
                .offset(x: distance)
                .twAnimation("animate-[\(animation)]", value: model.phase)
        } else {
            NativeUtilityChild(phase: model.phase, identities: identities)
                .tw("shift-[\(distance)] animate-[\(animation)]", value: model.phase)
        }
    }
}
private struct NativeUtilityChild: View {
    let phase: Int
    let identities: NativeIdentityRecorder
    @State private var identity = UUID()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        identities.values.append(identity)
        identities.phases.append(phase)
        identities.reduceMotion = reduceMotion
        return Text("Stable native content")
    }
}
private final class NativeMotionSamples: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [(time: TimeInterval, generation: Int)] = []
    var times: [TimeInterval] { lock.withLock { storage.map(\.time) } }
    func times(for generation: Int) -> [TimeInterval] {
        lock.withLock { storage.filter { $0.generation == generation }.map(\.time) }
    }
    var recentSamples: [String] {
        lock.withLock { storage.suffix(12).map { "generation \($0.generation): \($0.time)" } }
    }
    func append(_ time: TimeInterval, generation: Int) {
        lock.withLock { storage.append((time, generation)) }
    }
    func clear() { lock.withLock { storage.removeAll() } }
}
private struct NativeMotionProbe: CustomAnimation {
    // Give a loaded hosted renderer time to sample a transition before it completes.
    static let duration: TimeInterval = 1
    let samples: NativeMotionSamples
    var generation = 0
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.samples === rhs.samples && lhs.generation == rhs.generation }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(samples)); hasher.combine(generation) }
    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        samples.append(time, generation: generation)
        guard time < Self.duration else { return nil }
        return value.scaled(by: max(0, time / Self.duration))
    }
}
#endif
