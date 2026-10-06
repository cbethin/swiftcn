#if os(macOS)
import AppKit
import SnapshotTesting
import Testing

/// SwiftPM does not save Xcode attachments. Persist them for local review and CI uploads.
func savingVisualDiffs<Value>(_ strategy: Snapshotting<Value, NSImage>, name: String) -> Snapshotting<Value, NSImage> {
    var strategy = strategy
    let compare = strategy.diffing.diffV2
    let root = ProcessInfo.processInfo.environment["SNAPSHOT_ARTIFACTS"]
    strategy.diffing.diffV2 = { reference, actual in
        guard let difference = compare(reference, actual) else { return nil }
        if let root {
            do {
                let directory = URL(fileURLWithPath: root).appendingPathComponent(name, isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                for attachment in difference.1 {
                    if case .data(let data, let filename) = attachment {
                        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
                    }
                }
            } catch { Issue.record("Could not save visual differences: \(error)") }
        }
        return difference
    }
    return strategy
}
#endif
