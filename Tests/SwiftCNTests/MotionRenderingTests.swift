#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Hosted native motion", .serialized)
@MainActor
struct MotionRenderingTests {
    @Test(arguments: [false, true])
    func styleChangesInvokeNativeInterpolationWithoutAnimatingContent(dynamicString: Bool) {
        let samples = MotionSamples()
        let native = Animation(MotionProbeAnimation(samples: samples))
        let rules = TWGlobalRules(animations: ["probe": TWAnimation(native)])
        let model = MotionModel()
        let recorder = ContentRecorder()
        withHost(MotionHarness(model: model, recorder: recorder, dynamicString: dynamicString).twRules(rules)) { host in
            #expect(samples.times.isEmpty) // Mounting the surface does not start an animation.
            if ProcessInfo.processInfo.environment["SWIFTCN_EXPECT_MOTION"] == "1" {
                #expect(recorder.reduceMotion == false, "The interpolation job requires Reduce Motion off.")
            }
            model.active = true
            settle(host, seconds: 0.6)
            expectMotion(samples, reduceMotion: recorder.reduceMotion)
            #expect(!recorder.animations.isEmpty)
            #expect(recorder.animations.allSatisfy { $0 == nil })
            #expect(Set(recorder.identities).count == 1)
            samples.clear()
            model.active = false
            settle(host, seconds: 0.6)
            expectMotion(samples, reduceMotion: recorder.reduceMotion)
            #expect(Set(recorder.identities).count == 1)
        }
    }

    @Test func disabledTransactionsPreventStyleInterpolation() {
        let samples = MotionSamples()
        let model = MotionModel()
        let recorder = ContentRecorder()
        let view = MotionHarness(model: model, recorder: recorder, dynamicString: false)
            .twRules(.init(animations: ["probe": TWAnimation(Animation(MotionProbeAnimation(samples: samples)))]))
        withHost(view) { host in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { model.active = true }
            settle(host, seconds: 0.2)
            #expect(samples.times.isEmpty)
            #expect(Set(recorder.identities).count == 1)
        }
    }

    @Test func scopedAnimationPreservesTheAncestorAnimationForContent() {
        let model = MotionModel()
        let recorder = ContentRecorder()
        let native = Animation.linear(duration: 0.1)
        let view = MotionHarness(model: model, recorder: recorder, dynamicString: false)
            .twRules(.init(animations: ["probe": .spring]))
        withHost(view) { host in
            recorder.animations.removeAll()
            withAnimation(native) { model.active = true }
            settle(host, seconds: 0.2)
            #expect(recorder.animations.contains { $0 == native })
            #expect(recorder.animations.allSatisfy { $0 == native || $0 == nil })
        }
    }

    private func withHost<V: View>(_ view: V, run: (NSHostingView<V>) -> Void) {
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 160, height: 100)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        // Present the native host so frame scheduling does not depend on offscreen rendering.
        window.orderFront(nil)
        settle(host, seconds: 0.05)
        run(host)
        window.orderOut(nil)
        window.contentView = nil
    }

    private func settle<V: View>(_ host: NSHostingView<V>, seconds: TimeInterval) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    private func expectMotion(_ samples: MotionSamples, reduceMotion: Bool?) {
        if reduceMotion == true {
            #expect(samples.times.isEmpty)
        } else {
            #expect(samples.times.contains { $0 > 0 && $0 < 0.4 }, "Native sample times: \(samples.times)")
        }
    }
}

private final class MotionSamples: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [TimeInterval] = []
    var times: [TimeInterval] { lock.withLock { storage } }
    func append(_ time: TimeInterval) { lock.withLock { storage.append(time) } }
    func clear() { lock.withLock { storage.removeAll() } }
}

private struct MotionProbeAnimation: CustomAnimation {
    let samples: MotionSamples
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.samples === rhs.samples }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(samples)) }
    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        samples.append(time)
        guard time < 0.4 else { return nil }
        return value.scaled(by: max(0, time / 0.4))
    }
}

@MainActor private final class MotionModel: ObservableObject {
    @Published var active = false
}

@MainActor private final class ContentRecorder {
    var animations: [Animation?] = []
    var identities: [UUID] = []
    var reduceMotion: Bool?
}

private struct MotionHarness: View {
    @ObservedObject var model: MotionModel
    let recorder: ContentRecorder
    let dynamicString: Bool
    var body: some View {
        MotionContent(recorder: recorder, active: model.active)
            .transaction { recorder.animations.append($0.animation) }
            .tw(dynamicString
                ? "\(model.active ? "opacity-100" : "opacity-20") animate-probe"
                : "opacity-20 active:opacity-100 animate-probe",
                state: .init(isPressed: model.active))
    }
}

private struct MotionContent: View {
    let recorder: ContentRecorder
    let active: Bool
    @State private var identity = UUID()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        recorder.identities.append(identity)
        recorder.reduceMotion = reduceMotion
        return Rectangle().fill(.blue).frame(width: active ? 40 : 20, height: 20)
    }
}
#endif
