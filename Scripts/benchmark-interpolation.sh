#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/swiftcn-bench.XXXXXX")"
trap 'rm -rf "$scratch_dir"' EXIT

/usr/bin/xcrun swiftc --version
/usr/sbin/sysctl -n machdep.cpu.brand_string
cp "$repo_dir"/Sources/SwiftCN/*.swift "$scratch_dir/"
cp "$repo_dir/Benchmarks/Interpolation.swift" "$scratch_dir/"
/usr/bin/xcrun swiftc -O -whole-module-optimization -swift-version 6 -parse-as-library \
    "$scratch_dir"/*.swift \
    -o "$scratch_dir/interpolation"
"$scratch_dir/interpolation"
