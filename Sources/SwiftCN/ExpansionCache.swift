import Foundation
import os

/// Monotonic identifiers for theme and rule values.
/// Copies share a revision; any mutation that can change class expansion takes a new one.
enum TWRevision {
    /// Default-constructed themes and rules describe identical content, so they share this revision.
    static let standard: UInt64 = 0
    private static let counter = OSAllocatedUnfairLock(initialState: standard)

    static func next() -> UInt64 {
        counter.withLock { value in
            value += 1
            return value
        }
    }
}

/// Process-wide memo of top-level class token expansions.
///
/// Only literal tokens are cached. Tokens with typed interpolation payloads always expand
/// fresh, because their arguments carry arbitrary Swift values with no general identity.
/// Entries are keyed by the theme and rule revisions, so changing either misses the cache
/// instead of returning stale rules.
final class TWExpansionCache: @unchecked Sendable {
    struct Key: Hashable {
        let token: String
        let target: TWTarget?
        let rules: UInt64
        let theme: UInt64
    }

    static let shared = TWExpansionCache()

    /// Bounded so dynamic class strings cannot grow memory without limit.
    let capacity: Int
    private let lock = NSLock()
    private var storage: [Key: [TWRule]] = [:]

    init(capacity: Int = 4096) {
        precondition(capacity > 0, "Cache capacity must be positive.")
        self.capacity = capacity
    }

    var count: Int { lock.withLock { storage.count } }

    func rules(for key: Key) -> [TWRule]? {
        lock.withLock { storage[key] }
    }

    func insert(_ rules: [TWRule], for key: Key) {
        lock.withLock {
            // Clearing is cheaper than tracking recency and recovers on the next render pass.
            if storage.count >= capacity, storage[key] == nil { storage.removeAll(keepingCapacity: true) }
            storage[key] = rules
        }
    }

    func removeAll() {
        lock.withLock { storage.removeAll() }
    }
}
