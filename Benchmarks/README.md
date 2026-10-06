# Interpolation benchmark

Run from the repository root on macOS:

```sh
bash Scripts/benchmark-interpolation.sh
SWIFTCN_BENCH_ITERATIONS=10000 bash Scripts/benchmark-interpolation.sh
```

The script copies the sources into a temporary directory and compiles them with `-O`, whole-module optimization, and Swift 6.
It does not change the package graph or add a runtime dependency.

Each case has 200 warm-up operations and seven samples of 5,000 operations by default.
Each operation changes its numeric input.
The program consumes each result in a printed checksum.
It reports median thread CPU time, CPU ranges, and median elapsed time per operation.
Thread CPU time excludes periods when the thread does not run, but hardware, CPU frequency, and competing work still affect results.

The cases cover:

- Typed construction and tokenization with two numeric arguments.
- Runtime string construction and resolution with six utilities.
- Typed interpolation and resolution with the same six utilities.
- `cn` composition and resolution with the same utilities.
- An explicitly prepared base plus dynamic typed `TWStyle` values.
- Resolution with one registered native modifier.
- Resolution with 32 registered native modifiers, with one selected.

The last two cases measure slot selection and argument validation.
They do not invoke the SwiftUI modifier factories or measure their type-erased view chains.
The prepared base uses a fixed theme and registry; it does not model changes to either input.

This is a CPU microbenchmark, compiled in the same module as the library to access its internal resolver.
It does not measure body invalidation, layout, rendering, scrolling, memory allocations, or frame time.
Profile those costs in Instruments with the intended application and device.
Do not use these numbers as universal limits or CI timing thresholds.

Hosted collection tests live in `NativeUtilityRenderingTests`.
They check typed values, stable row state, editable fields, insertions, deletions, reordering, and conditional tag removal.
They run in native `VStack`, `LazyVStack`, and `List` containers with stable model IDs.

```sh
swift test --filter interpolatedCollectionRowsRetainTheirOwnState
swift test --filter repeatedResolutionKeepsEachRowsCurrentPayload
```

## Local comparison, October 5, 2026

Apple M4, macOS 27.0 (26A5388g), Apple Swift 6.4.0.34.1.
The baseline uses merged commit `aeaf721`.
The candidate moves the parser's five immutable lookup tables into static storage.
Both versions use the same benchmark source, compiler flags, inputs, and sample counts.
Both produce the same checksum.

| Operation | Baseline CPU median, µs | Candidate CPU median, µs |
| --- | ---: | ---: |
| Typed construction + tokenization | 2.86 | 2.31 |
| Runtime string resolution | 46.27 | 30.83 |
| Typed interpolation resolution | 48.73 | 33.11 |
| `cn` + typed resolution | 53.48 | 32.68 |
| Prepared base + typed styles | 5.83 | 5.74 |
| One registered modifier | 51.79 | 32.97 |
| 32 registered modifiers | 60.42 | 39.01 |

Read the [baseline output](results/2026-10-05-before.txt) and [candidate output](results/2026-10-05-after.txt) for ranges and elapsed timings.
The machine had other active work, so these are observations, not a controlled speedup guarantee.
Thread CPU timings reduce scheduling noise; they do not remove all system effects.
Construction plus tokenization is a separate two-argument case and is included in full resolution timings, not added to them.
The parser still resolves each class expression when its styled view updates.
Prepared styles reduce that work when their theme and registration inputs stay fixed.
