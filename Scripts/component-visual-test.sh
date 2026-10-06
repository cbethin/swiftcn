#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-verify}"
profile="${2:-local}"
if [[ "$mode" != verify && "$mode" != record ]]; then exit 2; fi
case "$profile" in
    local) reference_dir="$repo_dir/artifacts/component-baselines" ;;
    ci)
        if [[ "$(sw_vers -productVersion)" != 15.* || "$(/usr/bin/xcodebuild -version)" != *'Xcode 16.4'* ]]; then
            echo 'CI component baselines require macOS 15 and Xcode 16.4.' >&2; exit 2
        fi
        reference_dir="$repo_dir/Tests/SwiftCNVisualTests/__Snapshots__/components-macos-15-xcode-16.4"
        ;;
    *) exit 2 ;;
esac
mkdir -p "$reference_dir"
export SWIFTCN_COMPONENT_VISUAL_MODE="$mode"
export SWIFTCN_COMPONENT_SNAPSHOT_DIRECTORY="$reference_dir"
cd "$repo_dir"
/usr/bin/xcrun swift test --filter ComponentCatalogVisualTests
