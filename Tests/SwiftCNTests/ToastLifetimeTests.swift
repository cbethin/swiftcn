import Testing
@testable import SwiftCN

struct ToastLifetimeTests {
    @Test func pausePreservesRemainingTimeRatherThanRestartingTheDuration() {
        let start = ContinuousClock.now
        var lifetime = CNToastLifetime()
        lifetime.reset(duration: 5, paused: false, at: start)
        lifetime.pause(at: start.advanced(by: .seconds(2)))
        #expect(lifetime.deadline == nil)
        #expect(lifetime.remaining == .seconds(3))
        // Repeated pause notifications must not consume more time.
        lifetime.pause(at: start.advanced(by: .seconds(20)))
        lifetime.resume(at: start.advanced(by: .seconds(30)))
        #expect(lifetime.deadline == start.advanced(by: .seconds(33)))
        lifetime.resume(at: start.advanced(by: .seconds(31)))
        #expect(lifetime.deadline == start.advanced(by: .seconds(33)))
    }
    @Test func updatingAPausedToastResetsOnlyItsOwnRemainingTime() {
        let start = ContinuousClock.now
        var lifetime = CNToastLifetime()
        lifetime.reset(duration: 2, paused: true, at: start)
        #expect(lifetime.deadline == nil)
        lifetime.reset(duration: 7, paused: true, at: start.advanced(by: .seconds(8)))
        lifetime.resume(at: start.advanced(by: .seconds(10)))
        #expect(lifetime.deadline == start.advanced(by: .seconds(17)))
        lifetime.pause(at: start.advanced(by: .seconds(18)))
        #expect(lifetime.remaining == .zero)
    }
    @Test func persistentToastsDoNotAcquireADeadlineOnResume() {
        let start = ContinuousClock.now
        var lifetime = CNToastLifetime()
        lifetime.reset(duration: nil, paused: false, at: start)
        lifetime.pause(at: start)
        lifetime.resume(at: start.advanced(by: .seconds(90)))
        #expect(lifetime.deadline == nil)
        #expect(lifetime.remaining == nil)
    }
}
