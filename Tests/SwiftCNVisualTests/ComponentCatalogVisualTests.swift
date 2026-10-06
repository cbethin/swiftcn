#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SnapshotTesting
import SwiftCN
@testable import SwiftCNComponentGallery

@Suite("Component catalog visual regression", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_COMPONENT_VISUAL_MODE"] != nil))
@MainActor
struct ComponentCatalogVisualTests {
    // AppKit cacheDisplay cannot composite the native tab strip. iOS covers both
    // appearances; CatalogNativeRenderingTests verifies macOS selection and item identity.
    nonisolated private static var selectedComponents: [CNComponentGallery] {
        let requested = Set((ProcessInfo.processInfo.environment["SWIFTCN_COMPONENT_VISUAL_ONLY"] ?? "")
            .split(whereSeparator: { $0.isWhitespace }).map { $0.replacingOccurrences(of: "-", with: "_") })
        return CNComponentGallery.allCases.filter { $0 != .tabs && (requested.isEmpty || requested.contains($0.rawValue)) }
    }
    @Test(arguments: selectedComponents, [false, true])
    func catalog(component: CNComponentGallery, dark: Bool) throws {
        try snapshot(component, dark: dark, width: 720, large: false)
    }
    @Test(arguments: [CNComponentGallery.field, .input_group, .message, .questionnaire, .empty, .card, .radio_group, .typography, .pagination, .sidebar, .skeleton, .spinner, .table]
        .filter { selectedComponents.contains($0) })
    func narrowAndLarge(component: CNComponentGallery) throws {
        try snapshot(component, dark: false, width: 320, large: true)
    }
    private func snapshot(_ component: CNComponentGallery, dark: Bool, width: Int, large: Bool) throws {
        let environment = ProcessInfo.processInfo.environment
        let record = environment["SWIFTCN_COMPONENT_VISUAL_MODE"] == "record"
        let directory = try #require(environment["SWIFTCN_COMPONENT_SNAPSHOT_DIRECTORY"])
        let name = "\(component.rawValue)-\(dark ? "dark" : "light")-\(width)-\(large ? "large" : "standard")"
        let theme = TWTheme.standard
        let view = VStack(alignment: .leading, spacing: 16) {
            Text(component.title).tw("text-lg font-semibold")
            component.previewExample
        }.tw("p-6 w-full")
            .frame(width: CGFloat(width))
            .background(theme.color(.background, scheme: dark ? .dark : .light))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .scrollIndicators(.hidden)
            .cnLoadingPhase(0.35)
            .transaction { $0.animation = nil; $0.disablesAnimations = true }
        let host = NSHostingView(rootView: view)
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        if component == .carousel {
            // Pin the native scroller geometry before SwiftUI centers each page.
            // Otherwise AppKit can switch from overlay to legacy after layout.
            pinCarouselScrollers(host)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08))
        if component == .carousel {
            // SwiftUI can install the native scroll view during the first run-loop turn.
            pinCarouselScrollers(host)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08))
        }
        // Stop native indeterminate indicators at a reproducible frame; behavior tests cover state.
        stopIndicators(host)
        host.layoutSubtreeIfNeeded()
        let failure = withSnapshotTesting(record: record ? .all : .never) {
            verifySnapshot(of: host as NSView, as: savingVisualDiffs(.image, name: name),
                           named: name, snapshotDirectory: directory, testName: "component")
        }
        if !record, let failure { Issue.record("\(name): \(failure)") }
    }
    private func stopIndicators(_ view: NSView) {
        if let indicator = view as? NSProgressIndicator { indicator.stopAnimation(nil) }
        for child in view.subviews { stopIndicators(child) }
    }
    private func pinCarouselScrollers(_ view: NSView) {
        if let scroll = view as? NSScrollView {
            scroll.scrollerStyle = .legacy
            scroll.autohidesScrollers = false
            scroll.tile()
        }
        for child in view.subviews { pinCarouselScrollers(child) }
    }
}
#endif
