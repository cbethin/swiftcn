#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-verify}"
profile="${2:-local}"
export SDKROOT="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
if [[ "$mode" != "verify" && "$mode" != "record" ]]; then
    echo "Usage: bash Scripts/visual-test.sh [verify|record] [local|ci]" >&2
    exit 2
fi
case "$profile" in
    local) reference_dir="$repo_dir/artifacts/local-baselines" ;;
    ci)
        xcode_version="$(/usr/bin/xcodebuild -version)"
        if [[ "$(sw_vers -productVersion)" != 15.* || "$xcode_version" != *'Xcode 16.4'* ]]; then
            echo "The ci profile requires macOS 15 and Xcode 16.4. Use the local profile on this machine." >&2
            exit 2
        fi
        reference_dir="$repo_dir/Tests/SwiftCNVisualTests/__Snapshots__/macos-15-xcode-16.4"
        ;;
    *) echo "Unknown snapshot profile: $profile" >&2; exit 2 ;;
esac
mkdir -p "$reference_dir" "$repo_dir/artifacts/visual-diffs"
export SWIFTCN_VISUAL_MODE="$mode"
export SWIFTCN_SNAPSHOT_DIRECTORY="$reference_dir"
export SNAPSHOT_ARTIFACTS="$repo_dir/artifacts/visual-diffs"
cd "$repo_dir"
/usr/bin/xcrun swift test --sdk "$SDKROOT" --filter SwiftCNVisualTests
