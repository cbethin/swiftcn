#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Loading clock visibility", .serialized)
@MainActor
struct LoadingVisibilityTests {
    @Test func visibilityFollowsOcclusionAndRegularAppActivation() {
        typealias Probe = CNWindowVisibilityView
        #expect(Probe.isVisible(occlusion: .visible, appIsActive: true, appIsRegular: true, nonactivatingPanel: false))
        #expect(!Probe.isVisible(occlusion: [], appIsActive: true, appIsRegular: true, nonactivatingPanel: false))
        #expect(!Probe.isVisible(occlusion: .visible, appIsActive: false, appIsRegular: true, nonactivatingPanel: false))
        // Accessory apps and non-activating panels are meant to be read while another app is active.
        #expect(Probe.isVisible(occlusion: .visible, appIsActive: false, appIsRegular: false, nonactivatingPanel: false))
        #expect(Probe.isVisible(occlusion: .visible, appIsActive: false, appIsRegular: true, nonactivatingPanel: true))
        #expect(!Probe.isVisible(occlusion: [], appIsActive: false, appIsRegular: false, nonactivatingPanel: true))
    }

    /// Hosts that force an active scene phase, as AppKit apps had to, must still stop when nobody can see the window.
    @Test(arguments: HiddenWindow.allCases)
    func hiddenWindowsStopTheClockEvenWithAnActiveScenePhase(hidden: HiddenWindow) {
        let ticks = TickCounter()
        withWindow(ClockProbe(ticks: ticks).environment(\.scenePhase, .active)) { window in
            hidden.apply(to: window)
            settle(hidden == .miniaturized ? 1 : 0.4)
            ticks.count = 0
            settle(0.5)
            #expect(ticks.count == 0, "The loading clock ticked \(ticks.count) times while \(hidden).")
            hidden.restore(window)
        }
    }

    /// Without a scene phase override, the clock follows the hosting window. The CI session has a visible desktop.
    @Test func visibleWindowsRunTheClockWithoutAScenePhaseOverride() {
        let ticks = TickCounter()
        withWindow(ClockProbe(ticks: ticks)) { window in
            settle(0.3)
            ticks.count = 0
            settle(0.5)
            let expectMotion = ProcessInfo.processInfo.environment["SWIFTCN_EXPECT_MOTION"] == "1"
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                #expect(!expectMotion, "The motion job requires Reduce Motion off.")
                #expect(ticks.count == 0)
            } else if window.occlusionState.contains(.visible) {
                #expect(ticks.count > 3, "A visible AppKit-hosted window must run the loading clock.")
                window.orderOut(nil)
                settle(0.3)
                ticks.count = 0
                settle(0.5)
                #expect(ticks.count == 0, "Ordering the window out must stop the loading clock.")
                window.orderFront(nil)
                settle(0.3)
                ticks.count = 0
                settle(0.5)
                #expect(ticks.count > 3, "Showing the window again must resume the loading clock.")
            } else {
                // A locked screen occludes every window, so only a visible desktop can check the running path.
                #expect(!expectMotion, "The motion job requires a visible desktop.")
                #expect(ticks.count == 0)
            }
        }
    }

    @Test func fixedPhasesAndZeroDurationsNeverInstallTheProbe() {
        for view in [AnyView(ClockProbe(ticks: TickCounter()).cnLoadingPhase(0.4)),
                     AnyView(ClockProbe(ticks: TickCounter(), duration: 0))] {
            withWindow(view) { window in
                #expect(descendants(window.contentView!).allSatisfy { !($0 is CNWindowVisibilityView) })
            }
        }
        withWindow(ClockProbe(ticks: TickCounter())) { window in
            let probe = descendants(window.contentView!).first { $0 is CNWindowVisibilityView }
            // Reduce Motion stops the clock, so it needs no probe either.
            #expect((probe != nil) != NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
            #expect(probe?.hitTest(CGPoint(x: 1, y: 1)) == nil, "The probe must never take clicks.")
        }
    }

    /// Flattened rendering cannot host AppKit views. The probe must not leave a placeholder there.
    @Test func theProbeDrawsNothingInsideFlattenedContent() {
        func pixels<V: View>(_ view: V) -> Data {
            var data = Data()
            withWindow(view.drawingGroup()) { window in
                let host = window.contentView!
                host.layoutSubtreeIfNeeded()
                if let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    data = bitmap.representation(using: .png, properties: [:]) ?? Data()
                }
            }
            return data
        }
        let clocked = pixels(CNLoadingTimeline(duration: 1) { _ in Color.blue.frame(width: 40, height: 40) })
        let plain = pixels(Color.blue.frame(width: 40, height: 40))
        #expect(!clocked.isEmpty)
        #expect(clocked == plain)
    }

    private func withWindow<V: View>(_ view: V, run: (NSWindow) -> Void) {
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 80)
        let window = NSWindow(contentRect: CGRect(x: 200, y: 200, width: 120, height: 80),
                              styleMask: [.titled, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.orderFront(nil)
        settle(0.1)
        run(window)
        window.orderOut(nil)
        window.contentView = nil
    }
    private func settle(_ seconds: TimeInterval) { RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds)) }
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
}

enum HiddenWindow: CaseIterable, CustomStringConvertible {
    case orderedOut, miniaturized, covered
    var description: String {
        switch self {
        case .orderedOut: "the window was ordered out"
        case .miniaturized: "the window was minimised"
        case .covered: "another window covered it"
        }
    }
    @MainActor func apply(to window: NSWindow) {
        switch self {
        case .orderedOut: window.orderOut(nil)
        case .miniaturized: window.miniaturize(nil)
        case .covered:
            let cover = NSWindow(contentRect: window.frame.insetBy(dx: -40, dy: -40), styleMask: [.borderless],
                                 backing: .buffered, defer: false)
            cover.isReleasedWhenClosed = false
            cover.backgroundColor = .black
            cover.isOpaque = true
            cover.level = .floating
            cover.orderFront(nil)
            HiddenWindow.cover = cover
        }
    }
    @MainActor func restore(_ window: NSWindow) {
        switch self {
        case .orderedOut: break
        case .miniaturized: window.deminiaturize(nil)
        case .covered: HiddenWindow.cover?.orderOut(nil); HiddenWindow.cover = nil
        }
    }
    @MainActor private static var cover: NSWindow?
}

@MainActor private final class TickCounter { var count = 0 }

/// Counts the loading clock's frames directly, independent of what the frame draws.
private struct ClockProbe: View {
    let ticks: TickCounter
    var duration = 1.0
    var body: some View {
        CNLoadingTimeline(duration: duration) { phase in
            ticks.count += 1
            return Color.clear.frame(width: 40, height: 40)
        }
    }
}
#endif
