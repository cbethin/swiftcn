#!/usr/bin/env python3
"""Build, optionally test, and leave the four-app showcase running in Simulator."""
import argparse
import json
import os
from pathlib import Path
import subprocess

REPO = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--duo', action='store_true', help='Use the actual iPhone Duo device and iOS 27.1 runtime')
parser.add_argument('--test', action='store_true', help='Run the four native workflow tests before opening the app')
parser.add_argument('--viewer', type=Path, help='Open a specific DeviceHub.app when using a different viewer from the build toolchain')
args = parser.parse_args()

def run(*command, capture=False):
    result = subprocess.run(command, cwd=REPO, check=True, text=True, capture_output=capture)
    return result.stdout.strip() if capture else None

runtime_list = json.loads(run('xcrun', 'simctl', 'list', 'runtimes', '-j', capture=True))['runtimes']
sdk_version = run('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version', capture=True)
if args.duo and sdk_version != '27.1':
    raise SystemExit('Select Xcode 27.1 with DEVELOPER_DIR for iPhone Duo. Xcode 27.0 and 27.2 do not provide the supported Duo toolchain.')
runtime = next((item for item in runtime_list if item.get('isAvailable') and item['version'] == ('27.1' if args.duo else sdk_version)), None)
if runtime is None:
    raise SystemExit('Install the iOS 27.1 Duo runtime and select a Duo-capable Xcode with DEVELOPER_DIR.' if args.duo else f'Install the iOS {sdk_version} runtime.')
types = json.loads(run('xcrun', 'simctl', 'list', 'devicetypes', '-j', capture=True))['devicetypes']
device_type = 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo' if args.duo else 'com.apple.CoreSimulator.SimDeviceType.iPhone-16'
if not any(item['identifier'] == device_type for item in types):
    raise SystemExit('The selected Xcode does not include the iPhone Duo device type. Select a Duo-capable Xcode with DEVELOPER_DIR.')
name = 'swiftcn-showcase-duo' if args.duo else 'swiftcn-showcase-iphone'
devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j', capture=True))['devices']
device = next((item for item in devices.get(runtime['identifier'], []) if item['name'] == name and item['deviceTypeIdentifier'] == device_type), None)
if device is None:
    device = {'udid': run('xcrun', 'simctl', 'create', name, device_type, runtime['identifier'], capture=True), 'state': 'Shutdown'}
udid = device['udid']
artifacts = REPO / 'artifacts' / 'showcase'
artifacts.mkdir(parents=True, exist_ok=True)
(artifacts / 'device.json').write_text(json.dumps({'udid': udid, 'runtime': runtime['version'], 'sdk': sdk_version, 'type': device_type}, indent=2))
run('xcodegen', 'generate', '--spec', 'Examples/Showcase/project.yml')
build = ['xcodebuild', '-jobs', '4', '-project', 'Examples/Showcase/SwiftCNShowcase.xcodeproj', '-scheme', 'SwiftCNShowcase',
         '-derivedDataPath', str(artifacts / 'build'), '-destination', f'platform=iOS Simulator,id={udid}']
if device['state'] != 'Booted':
    run('xcrun', 'simctl', 'boot', udid)
run('xcrun', 'simctl', 'bootstatus', udid, '-b')
with (artifacts / 'build.log').open('w') as log:
    subprocess.run(build + ['build-for-testing' if args.test else 'build'], cwd=REPO, stdout=log, stderr=subprocess.STDOUT, check=True)
if args.test:
    plans = list((artifacts / 'build' / 'Build' / 'Products').glob('*.xctestrun'))
    if not plans:
        raise SystemExit('Xcode did not produce a test run file. See artifacts/showcase/build.log.')
    plan = max(plans, key=lambda path: path.stat().st_mtime)
    test = ['xcodebuild', '-xctestrun', str(plan), '-destination', f'platform=iOS Simulator,id={udid}',
            '-parallel-testing-enabled', 'NO', '-resultBundlePath', str(artifacts / f'workflows-{os.getpid()}.xcresult'), 'test-without-building']
    with (artifacts / 'tests.log').open('w') as log:
        subprocess.run(test, cwd=REPO, stdout=log, stderr=subprocess.STDOUT, check=True)
app = artifacts / 'build' / 'Build' / 'Products' / 'Debug-iphonesimulator' / 'SwiftCNShowcase.app'
run('xcrun', 'simctl', 'install', udid, str(app))
run('xcrun', 'simctl', 'launch', '--terminate-running-process', udid, 'dev.swiftcn.showcase')
developer = os.environ.get('DEVELOPER_DIR') or run('xcode-select', '-p', capture=True)
simulator = args.viewer or next((path for path in [Path(developer).parent / 'Applications' / 'DeviceHub.app', Path(developer) / 'Applications' / 'Simulator.app'] if path.exists()), None)
if simulator is None:
    raise SystemExit('The app is running, but this Xcode has no Device Hub or Simulator application.')
if not simulator.is_dir():
    raise SystemExit(f'The app is running, but the viewer does not exist: {simulator}')
run('open', '-a', str(simulator), '--args', '-CurrentDeviceUDID', udid)
print(f'SwiftCN Showcase is running on {name} ({udid}). Your local app data is preserved.')
