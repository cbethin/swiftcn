import Foundation
import Darwin
import SwiftUI

/// Compile with the library sources so resolution can be measured without rendering.
@main
struct InterpolationBenchmark {
    static func main() throws {
        let iterations = Int(ProcessInfo.processInfo.environment["SWIFTCN_BENCH_ITERATIONS"] ?? "5000") ?? 5000
        guard iterations > 0 else { fatalError("Iterations must be positive") }
        let rules = TWGlobalRules()
        let registered = TWGlobalRules(modifiers: [
            "shift": .value(default: CGFloat.zero) { view, distance in view.offset(x: distance) }
        ])
        let broad = TWGlobalRules(modifiers: Dictionary(uniqueKeysWithValues: (0..<32).map { index in
            ("plugin-\(index)", TWNativeUtility.value(default: CGFloat.zero) { view, distance in view.offset(x: distance) })
        }))
        let base: TWClasses = "p-4 rounded-lg bg-surface text-primary"
        let prepared = try TWStyle.parse(base)
        var checksum = 0.0

        func resolve(_ style: TWStyle, _ rules: TWGlobalRules) -> Double {
            let result = TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: .init(), globalRules: rules)
            return Double(result.width ?? 0) + result.opacity + Double(result.padding.top) + Double(result.nativeSlots.count)
        }
        func measure(_ name: String, _ operation: (Int) throws -> Double) rethrows {
            for index in 0..<200 { checksum += try operation(index) }
            var samples: [Double] = []
            var elapsedSamples: [Double] = []
            for round in 0..<7 {
                let start = ContinuousClock.now
                let cpuStart = cpuNanoseconds()
                for index in 0..<iterations { checksum += try operation(index + round) }
                samples.append(Double(cpuNanoseconds() - cpuStart) / Double(iterations))
                let elapsed = start.duration(to: .now).components
                elapsedSamples.append((Double(elapsed.seconds) * 1e9 + Double(elapsed.attoseconds) / 1e9) / Double(iterations))
            }
            samples.sort()
            elapsedSamples.sort()
            print("\(name): CPU median \(String(format: "%.2f", samples[3] / 1000)) us/op; CPU range \(String(format: "%.2f", samples[0] / 1000))–\(String(format: "%.2f", samples[6] / 1000)); elapsed median \(String(format: "%.2f", elapsedSamples[3] / 1000)) us/op")
        }

        print("Release CPU benchmark; \(iterations) operations/sample, 7 samples, 200 warm-up operations/case")
        print("OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        try measure("typed construct + tokenize") { index in
            let classes: TWClasses = "w-[\(CGFloat(100 + index % 100))] opacity-[\(0.8)]"
            return Double(try classes.tokens().count)
        }
        measure("runtime String resolve") { index in
            let classes: String = "p-4 rounded-lg bg-surface text-primary w-[\(100 + index % 100)] opacity-[0.8]"
            return resolve(.classes(classes), rules)
        }
        measure("typed interpolation resolve") { index in
            let classes: TWClasses = "p-4 rounded-lg bg-surface text-primary w-[\(CGFloat(100 + index % 100))] opacity-[\(0.8)]"
            return resolve(.classes(classes), rules)
        }
        measure("cn + typed interpolation resolve") { index in
            let classes = cn(base, "w-[\(CGFloat(100 + index % 100))] opacity-[\(0.8)]")
            return resolve(.classes(classes), rules)
        }
        measure("prepared base + typed styles resolve") { index in
            resolve(TWStyle(prepared, .w(CGFloat(100 + index % 100)), .opacity(0.8)), rules)
        }
        measure("one registered modifier resolve") { index in
            let classes = cn(base, "w-[\(CGFloat(100 + index % 100))] shift-[\(CGFloat(index % 10))]")
            return resolve(.classes(classes), registered)
        }
        measure("32 registered modifiers resolve") { index in
            let classes = cn(base, "w-[\(CGFloat(100 + index % 100))] plugin-0-[\(CGFloat(index % 10))]")
            return resolve(.classes(classes), broad)
        }
        // Print accumulated results to keep the measured operations observable.
        print("Checksum: \(checksum)")
        print("This measures construction and resolution, not SwiftUI layout, drawing, scrolling, or FPS.")
    }

    private static func cpuNanoseconds() -> UInt64 {
        var time = timespec()
        precondition(clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time) == 0)
        return UInt64(time.tv_sec) * 1_000_000_000 + UInt64(time.tv_nsec)
    }
}
