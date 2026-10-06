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
    @Test(arguments: CNComponentGallery.allCases.filter { $0 != .tabs }, [false, true])
    func catalog(component: CNComponentGallery, dark: Bool) throws {
        try snapshot(component, dark: dark, width: 720, large: false)
    }
    @Test(arguments: [CNComponentGallery.field, .input_group, .message, .questionnaire, .empty, .card, .radio_group, .typography])
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
            component.example
        }.tw("p-6 w-full")
            .frame(width: CGFloat(width))
            .background(theme.color(.background, scheme: dark ? .dark : .light))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .scrollIndicators(.hidden)
            .transaction { $0.animation = nil; $0.disablesAnimations = true }
        let host = NSHostingView(rootView: view)
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08))
        // Stop native indeterminate indicators at a reproducible frame; behavior tests cover state.
        stopIndicators(host)
        host.layoutSubtreeIfNeeded()
        let failure = withSnapshotTesting(record: record ? .all : .never) {
            verifySnapshot(of: host as NSView, as: .image,
                           named: name, snapshotDirectory: directory, testName: "component")
        }
        if !record, let failure { Issue.record("\(name): \(failure)") }
    }
    private func stopIndicators(_ view: NSView) {
        if let indicator = view as? NSProgressIndicator { indicator.stopAnimation(nil) }
        for child in view.subviews { stopIndicators(child) }
    }
}
#endif
