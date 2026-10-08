#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
platform="${1:-macos}"
if [[ $# -gt 0 ]]; then shift; fi
case "$platform" in
  macos) scheme=SwiftCNInteractionsMac ;;
  ios) scheme=SwiftCNInteractionsIOS ;;
  *) echo "Usage: bash Scripts/interaction-test.sh [macos|ios] [xcodebuild arguments]" >&2; exit 2 ;;
esac
command -v xcodegen >/dev/null || { echo "Install XcodeGen with: brew install xcodegen" >&2; exit 1; }

output_dir="$repo_dir/artifacts/interactions/$platform-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$output_dir"
owned_simulator=""
finish() {
  local status=$?
  if [[ -n "$owned_simulator" ]]; then
    xcrun simctl shutdown "$owned_simulator" >/dev/null 2>&1 || true
    xcrun simctl delete "$owned_simulator" >/dev/null 2>&1 || true
  fi
  if [[ -d "$output_dir/results.xcresult" ]]; then
    xcrun xcresulttool get test-results summary --path "$output_dir/results.xcresult" \
      > "$output_dir/summary.json" 2> "$output_dir/summary-error.log" || true
  fi
  echo "Interaction results: $output_dir"
  exit "$status"
}
trap finish EXIT

xcodegen generate --spec "$repo_dir/Examples/Components/project.yml"
destination="${SWIFTCN_UI_DESTINATION:-}"
if [[ -z "$destination" ]]; then
  if [[ "$platform" == macos ]]; then
    destination="platform=macOS,arch=$(uname -m)"
  else
    # Every run owns a new simulator. Never reset or delete a caller's device.
    owned_simulator="$(python3 - <<'PY'
import json, os, subprocess
def run(*args):
    return subprocess.check_output(['xcrun', *args], text=True).strip()
version = run('--sdk', 'iphonesimulator', '--show-sdk-version')
runtimes = json.loads(run('simctl', 'list', 'runtimes', '-j'))['runtimes']
runtime = next((r for r in runtimes if r.get('isAvailable') and r['name'].startswith('iOS ') and r['version'] == version), None)
if runtime is None:
    raise SystemExit(f'Install the iOS {version} simulator runtime for the selected Xcode.')
family = os.environ.get('SWIFTCN_UI_DEVICE_FAMILY', 'iPhone')
device = next((d for d in runtime['supportedDeviceTypes'] if d['name'].startswith(family + ' ')), None)
if device is None:
    raise SystemExit(f'No {family} simulator is available in iOS {version}.')
print(run('simctl', 'create', f'swiftcn-interactions-{os.getpid()}', device['identifier'], runtime['identifier']))
PY
)"
    xcrun simctl boot "$owned_simulator"
    xcrun simctl bootstatus "$owned_simulator" -b
    destination="platform=iOS Simulator,id=$owned_simulator"
  fi
fi

# Retry and parallel test execution stay off: failures must remain visible.
xcodebuild test -project "$repo_dir/Examples/Components/SwiftCNInteractions.xcodeproj" \
  -scheme "$scheme" -destination "$destination" \
  -derivedDataPath "$repo_dir/artifacts/interaction-derived-data-$platform" \
  -resultBundlePath "$output_dir/results.xcresult" \
  -parallel-testing-enabled NO \
  "$@" 2>&1 | tee "$output_dir/test.log"
