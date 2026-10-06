#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
sdk_dir="$(/usr/bin/xcrun --sdk iphonesimulator --show-sdk-path)"
compiler_path="$(/usr/bin/xcrun --find swiftc)"
machine_arch="$(uname -m)"
output_dir="$repo_dir/artifacts/ios"
mkdir -p "$output_dir"

"$compiler_path" -sdk "$sdk_dir" -target "$machine_arch-apple-ios17.0-simulator" \
    -swift-version 6 -warnings-as-errors -parse-as-library \
    -module-name SwiftCN -emit-module -emit-module-path "$output_dir/SwiftCN.swiftmodule" \
    -emit-library -o "$output_dir/libSwiftCN.dylib" \
    "$repo_dir"/Sources/SwiftCN/*.swift
echo "SwiftCN compiles for the iOS simulator (minimum iOS 17)."
