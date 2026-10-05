#if os(macOS)
import AppKit
import SnapshotTesting
import Testing

@Suite("iOS visual regression", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_IOS_SCREENSHOTS"] != nil))
@MainActor
struct IOSVisualTests {
    @Test(arguments: ["controls", "rules"], ["light-standard", "dark-standard", "light-large-text", "dark-large-text"])
    func screenshots(scene: String, configuration: String) throws {
        let environment = ProcessInfo.processInfo.environment
        let directory = try #require(environment["SWIFTCN_IOS_SCREENSHOTS"])
        let references = try #require(environment["SWIFTCN_SNAPSHOT_DIRECTORY"])
        let record = environment["SWIFTCN_VISUAL_MODE"] == "record"
        let name = "\(scene)-\(configuration)"
        let image = try #require(NSImage(contentsOfFile: "\(directory)/\(name).png"))
        let failure = withSnapshotTesting(record: record ? .all : .never) {
            verifySnapshot(of: image, as: .image, named: name, snapshotDirectory: references, testName: "ios")
        }
        if record {
            #expect(FileManager.default.fileExists(atPath: "\(references)/ios.\(name).png"))
        } else if let failure { Issue.record("\(name): \(failure)") }
    }
}
#endif
