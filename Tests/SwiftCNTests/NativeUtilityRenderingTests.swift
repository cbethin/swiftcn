#if os(macOS)
import AppKit
import QuartzCore
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

    @Test(arguments: [
        (false, false, false), (false, false, true), (false, true, false), (false, true, true),
        (true, false, false), (true, false, true), (true, true, false), (true, true, true)
    ])
    func argumentChangesAndTagRemovalPreserveIdentityAndNativeMotion(disabledTransaction: Bool, transform: Bool, reconfigureAnimation: Bool) {
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
        let view = NativeUtilityHarness(model: model, identities: identities, samples: reconfigureAnimation ? samples : nil)
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
                    #expect(samples.times(for: reconfigureAnimation ? phase : 0).contains { $0 > 0 && $0 < NativeMotionProbe.duration },
                        "Phase \(phase), native samples: \(samples.recentSamples)")
                }
                samples.clear()
            }
            #expect(Set(identities.phases) == [0, 1, 2])
        }
    }

    @Test(arguments: [
        (false, false, false), (false, false, true), (false, true, false), (false, true, true),
        (true, false, false), (true, false, true), (true, true, false), (true, true, true)
    ])
    func nativeOffsetAllowsReplacingTheCustomAnimation(zeroDelay: Bool, scoped: Bool, decorated: Bool) {
        let model = NativeUtilityModel()
        let identities = NativeIdentityRecorder()
        let samples = NativeMotionSamples()
        withHost(NativeOffsetHarness(model: model, identities: identities, samples: samples,
            zeroDelay: zeroDelay, scoped: scoped, decorated: decorated)) { host in
            for phase in [1, 2, 0] {
                model.phase = phase
                settle(host, seconds: NativeMotionProbe.duration + 0.3)
                #expect(samples.times(for: phase).contains { $0 > 0 && $0 < NativeMotionProbe.duration },
                    "Native phase \(phase), samples: \(samples.recentSamples)")
                #expect(Set(identities.values).count == 1)
                samples.clear()
            }
        }
    }

    @Test func registeredOffsetRetargetsWithoutSiblingDecorations() {
        let model = NativeUtilityModel()
        let identities = NativeIdentityRecorder()
        let samples = NativeMotionSamples()
        let rules = TWGlobalRules(animations: ["probe": TWAnimation(Animation(NativeMotionProbe(samples: samples)))], modifiers: [
            "shift": .argument(default: "0") { argument, _ in argument.points.map { NativeShift(distance: $0) } }
        ])
        withHost(BareNativeUtilityHarness(model: model, identities: identities).twRules(rules)) { host in
            for phase in [1, 2, 0] {
                model.phase = phase
                settle(host, seconds: NativeMotionProbe.duration + 0.3)
                #expect(samples.times.contains { $0 > 0 && $0 < NativeMotionProbe.duration },
                    "Bare phase \(phase), samples: \(samples.recentSamples)")
                #expect(Set(identities.values).count == 1)
                samples.clear()
            }
        }
    }

    @Test(arguments: [false, true])
    func composedOffsetsInterpolatePresentationPixels(registered: Bool) throws {
        let model = NativeUtilityModel()
        model.phase = 1
        let identities = NativeIdentityRecorder()
        let rules = TWGlobalRules(modifiers: [
            "glass": .view { view, active in view.background(active ? Color.blue : .clear) },
            "shift": .argument(default: CGFloat.zero,
                parse: { argument, _ in argument.points }) { view, distance in view.offset(x: distance) }
        ])
        try withHost(OffsetPixelHarness(model: model, identities: identities, registered: registered).twRules(rules)) { host in
            for phase in [2, 1] {
                let start = try bluePosition(host)
                model.phase = phase
                var positions: [CGFloat] = []
                for _ in 0..<12 {
                    settle(host, seconds: 0.1)
                    positions.append(try bluePosition(host))
                }
                let end = start + (phase == 2 ? 40 : -40)
                #expect(abs(try #require(positions.last) - end) < 1)
                #expect(positions.contains { $0 > min(start, end) + 2 && $0 < max(start, end) - 2 },
                    "Rendered offset positions: \(positions)")
                #expect(Set(identities.values).count == 1)
            }
        }
    }

    private func bluePosition<V: View>(_ host: NSHostingView<V>) throws -> CGFloat {
        host.wantsLayer = true
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        CATransaction.flush()
        let layer = try #require(host.layer)
        let scale = host.window?.backingScaleFactor ?? 1
        let width = Int(host.bounds.width * scale), height = Int(host.bounds.height * scale)
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.scaleBy(x: scale, y: scale)
        (layer.presentation() ?? layer).render(in: context)
        let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        let left = try #require((0..<width).first { x in
            let index = ((height / 2) * width + x) * 4
            return Int(bytes[index + 2]) > Int(bytes[index]) + 100
                && Int(bytes[index + 2]) > Int(bytes[index + 1]) + 35
        })
        return CGFloat(left) / scale
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

    private func withHost<V: View>(_ view: V, run: (NSHostingView<V>) throws -> Void) rethrows {
        let host = NSHostingView(rootView: view)
        // Keep the decorated content visible through the largest tested offset.
        // macOS 15 can stop sampling a custom animation when its layer is clipped.
        host.frame = CGRect(x: 0, y: 0, width: 500, height: 100)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        settle(host, seconds: 0.1)
        try run(host)
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
    @ViewBuilder
    var body: some View {
        let content = NativeUtilityChild(phase: model.phase, identities: identities)
            .tw(cn {
                if callerAnimation {
                    if model.phase != 0 { "shift" }
                } else {
                    "animate-probe"
                    if model.phase != 0 { "glass shift-[\(model.phase * 40)]" }
                }
            }, value: model.phase)
        if let samples {
            content.twRules { rules in
                    // Distinguish each transition from the previous probe's completed timeline.
                    rules.animations["probe"] = TWAnimation(Animation(NativeMotionProbe(samples: samples, generation: model.phase)))
            }
        } else {
            content
        }
    }
}
private struct BareNativeUtilityHarness: View {
    @ObservedObject var model: NativeUtilityModel
    let identities: NativeIdentityRecorder
    var body: some View {
        NativeUtilityChild(phase: model.phase, identities: identities)
            .tw("shift-[\(model.phase * 40)] animate-probe", value: model.phase)
    }
}
private struct NativeOffsetHarness: View {
    @ObservedObject var model: NativeUtilityModel
    let identities: NativeIdentityRecorder
    let samples: NativeMotionSamples
    var zeroDelay = false
    var scoped = false
    var decorated = false
    private func shifted<V: View>(_ view: V) -> AnyView {
        if decorated {
            return AnyView(AnyView(AnyView(view).background(model.phase != 0 ? Color.blue : .clear))
                .offset(x: CGFloat(model.phase * 40)))
        }
        return AnyView(view.offset(x: CGFloat(model.phase * 40)))
    }
    var body: some View {
        let native = Animation(NativeMotionProbe(samples: samples, generation: model.phase))
        let animation = zeroDelay ? native.delay(0) : native
        return Group {
            if scoped {
                NativeUtilityChild(phase: model.phase, identities: identities)
                    .transaction { $0.animation = animation } body: { surface in
                        shifted(surface)
                    }
            } else {
                shifted(NativeUtilityChild(phase: model.phase, identities: identities))
            }
        }
        .animation(animation, value: model.phase)
    }
}
private struct OffsetPixelHarness: View {
    @ObservedObject var model: NativeUtilityModel
    let identities: NativeIdentityRecorder
    let registered: Bool
    @ViewBuilder var body: some View {
        if registered {
            NativeUtilityChild(phase: model.phase, identities: identities)
                .tw("p-3 glass shift-[\(model.phase * 40)] animate-linear duration-1000", value: model.phase)
        } else {
            NativeUtilityChild(phase: model.phase, identities: identities)
                .padding(12).background(Color.blue).offset(x: CGFloat(model.phase * 40))
                .animation(.linear(duration: 1), value: model.phase)
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
