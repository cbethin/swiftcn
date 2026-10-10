#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-verify}"
profile="${2:-local}"
if [[ "$mode" != verify && "$mode" != record ]]; then exit 2; fi
case "$profile" in
    local) reference_dir="$repo_dir/artifacts/component-baselines" ;;
    ci)
        if [[ "$(sw_vers -productVersion)" != 15.* || "$(/usr/bin/xcodebuild -version)" != *'Xcode 26.3'* ]]; then
            echo 'CI component baselines require macOS 15 and Xcode 26.3.' >&2; exit 2
        fi
        reference_dir="$repo_dir/Tests/SwiftCNVisualTests/__Snapshots__/components-macos-15-xcode-26.3"
        ;;
    *) exit 2 ;;
esac
if [[ -n "${SWIFTCN_COMPONENT_VISUAL_ONLY:-}" ]]; then
    python3 - "$repo_dir/Components/catalog.json" "$SWIFTCN_COMPONENT_VISUAL_ONLY" <<'PYTHON'
import json, sys
allowed = {entry['slug'] for entry in json.load(open(sys.argv[1]))}
requested = set(sys.argv[2].split())
unknown = requested - allowed
if unknown:
    raise SystemExit('Unknown component slugs: ' + ', '.join(sorted(unknown)))
if 'tabs' in requested:
    raise SystemExit('The macOS tab strip cannot be captured offscreen. Use iOS candidates for tabs.')
PYTHON
fi
mkdir -p "$reference_dir"
export SNAPSHOT_ARTIFACTS="$repo_dir/artifacts/visual-diffs"
export SWIFTCN_COMPONENT_VISUAL_MODE="$mode"
export SWIFTCN_COMPONENT_SNAPSHOT_DIRECTORY="$reference_dir"
cd "$repo_dir"
/usr/bin/xcrun swift test --filter ComponentCatalogVisualTests
