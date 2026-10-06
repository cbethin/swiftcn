#if os(macOS)
import AppKit
import SnapshotTesting
import Testing
@testable import SwiftCNComponentGallery

@Suite("iOS component visual regression", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_IOS_COMPONENT_SCREENSHOTS"] != nil))
@MainActor
struct IOSComponentVisualTests {
    @Test(arguments: CNComponentGallery.allCases)
    func screenshots(component: CNComponentGallery) throws {
        let environment = ProcessInfo.processInfo.environment
        let directory = try #require(environment["SWIFTCN_IOS_COMPONENT_SCREENSHOTS"])
        let references = try #require(environment["SWIFTCN_SNAPSHOT_DIRECTORY"])
        let record = environment["SWIFTCN_VISUAL_MODE"] == "record"
        let slug = component.rawValue.replacingOccurrences(of: "_", with: "-")
        let narrow = ["field", "input-group", "message", "questionnaire", "empty", "card", "radio-group", "typography"].contains(slug)
        for configuration in ["light-standard", "dark-standard"] + (narrow ? ["light-large-text"] : []) {
            let name = "component-\(slug)-\(configuration)"
            let image = try #require(NSImage(contentsOfFile: "\(directory)/\(name).png"))
            let failure = withSnapshotTesting(record: record ? .all : .never) {
                verifySnapshot(of: image, as: savingVisualDiffs(.image, name: name),
                               named: name, snapshotDirectory: references, testName: "ios")
            }
            if !record, let failure { Issue.record("\(name): \(failure)") }
        }
    }
}
#endif
