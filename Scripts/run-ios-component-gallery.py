#!/usr/bin/env python3
"""Build and launch the interactive component gallery on its own iPhone simulator."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]

def run(*args, capture=False):
    result = subprocess.run(args, check=True, text=True, capture_output=capture)
    return result.stdout.strip() if capture else None

sdk = run('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path', capture=True)
version = run('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version', capture=True)
architecture = run('uname', '-m', capture=True)
app = REPO / 'artifacts' / 'SwiftCN iOS Component Gallery.app'
app.mkdir(parents=True, exist_ok=True)
bundle_id = 'dev.swiftcn.component-gallery.ios'
with (app / 'Info.plist').open('wb') as file:
    plistlib.dump(dict(CFBundleIdentifier=bundle_id, CFBundleExecutable='SwiftCNComponentGallery',
        CFBundleName='SwiftCN Component Gallery', CFBundleVersion='1', CFBundleShortVersionString='0.1.0',
        CFBundlePackageType='APPL', MinimumOSVersion='17.0', UIDeviceFamily=[1, 2], UILaunchScreen={},
        UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft',
                                          'UIInterfaceOrientationLandscapeRight']), file)
with tempfile.TemporaryDirectory(prefix='swiftcn-interactive-gallery-') as temporary:
    frozen = Path(temporary)
    sources = sorted((REPO / 'Sources/SwiftCN').glob('*.swift'))
    sources += sorted((REPO / 'Examples/Components/Sources').glob('*.swift'))
    for source in sources:
        text = source.read_text()
        if source.name != 'ComponentSource.swift':
            text = text.replace('import SwiftCN\n', '')
        (frozen / source.name).write_text(text)
    subprocess.run(['xcrun', 'swiftc', '-sdk', sdk, '-target', f'{architecture}-apple-ios17.0-simulator',
        '-swift-version', '6', '-warnings-as-errors', '-parse-as-library', '-module-name', 'SwiftCNComponentGallery',
        *map(str, sorted(frozen.glob('*.swift'))), '-o', str(app / 'SwiftCNComponentGallery')],
        check=True, env=dict(os.environ, SDKROOT=sdk))
run('/usr/bin/codesign', '--force', '--sign', '-', str(app))
runtimes = json.loads(run('xcrun', 'simctl', 'list', 'runtimes', '-j', capture=True))['runtimes']
runtime_info = next((r for r in runtimes if r.get('isAvailable') and r['name'].startswith('iOS ')
                and r['version'] == version), None)
if runtime_info is None:
    raise SystemExit(f'Install the iOS {version} simulator runtime in Xcode to run the gallery.')
runtime = runtime_info['identifier']
devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j', capture=True))['devices']
device = next((d for d in devices.get(runtime, []) if d['name'] == 'swiftcn-component-gallery'), None)
if device is None:
    device_type = next(d['identifier'] for d in runtime_info['supportedDeviceTypes']
                       if d['name'].startswith('iPhone ') and 'Pro Max' not in d['name'])
    udid = run('xcrun', 'simctl', 'create', 'swiftcn-component-gallery', device_type, runtime, capture=True)
    device = dict(udid=udid, state='Shutdown')
if device['state'] != 'Booted':
    run('xcrun', 'simctl', 'boot', device['udid'])
run('xcrun', 'simctl', 'bootstatus', device['udid'], '-b')
run('xcrun', 'simctl', 'install', device['udid'], str(app))
run('xcrun', 'simctl', 'launch', '--terminate-running-process', device['udid'], bundle_id)
print(f'Interactive gallery running on {device["udid"]}. Open swiftcn-component-gallery in Xcode Device Hub or Simulator.')
