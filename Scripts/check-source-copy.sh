#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/swiftcn-copy.XXXXXX")"
trap 'rm -rf "$scratch_dir"' EXIT

mkdir -p "$scratch_dir/Sources/OwnedStyles"
cp "$repo_dir"/Sources/SwiftCN/*.swift "$scratch_dir/Sources/OwnedStyles/"
cat > "$scratch_dir/Package.swift" <<'SWIFT'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "OwnedStyles",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "OwnedStyles", targets: ["OwnedStyles"])],
    targets: [.target(name: "OwnedStyles")]
)
SWIFT
swift build --package-path "$scratch_dir"
echo "Copied sources compile without SwiftCN or external dependencies."
