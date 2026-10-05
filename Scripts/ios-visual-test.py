#!/usr/bin/env python3
"""Capture a dedicated iPhone simulator and compare reviewed image references."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import time

REPO = Path(__file__).resolve().parent.parent
XCRUN = "/usr/bin/xcrun"


def run(*args, capture=False, **kwargs):
    result = subprocess.run(args, check=True, text=True, capture_output=capture, **kwargs)
    return result.stdout.strip() if capture else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["record", "verify"], nargs="?", default="verify")
    parser.add_argument("profile", choices=["local", "ci"], nargs="?", default="local")
    args = parser.parse_args()
    if args.profile == "ci":
        sdk_version = run(XCRUN, "--sdk", "iphonesimulator", "--show-sdk-version", capture=True)
        if sdk_version != "18.5" or "Xcode 16.4" not in run("/usr/bin/xcodebuild", "-version", capture=True):
            raise RuntimeError("The ci profile requires Xcode 16.4 with iOS 18.5. Use the local profile.")
    artifacts = REPO / "artifacts" / "ios-visual"
    artifacts.mkdir(parents=True, exist_ok=True)
    app = artifacts / "SwiftCNVisualHost.app"
    app.mkdir(exist_ok=True)
    bundle_id = "dev.swiftcn.visual-tests"
    with (app / "Info.plist").open("wb") as handle:
        plistlib.dump({"CFBundleIdentifier": bundle_id, "CFBundleExecutable": "SwiftCNVisualHost",
                      "CFBundleName": "SwiftCN Visual Host", "CFBundleVersion": "1",
                      "CFBundleShortVersionString": "1", "CFBundlePackageType": "APPL",
                      "MinimumOSVersion": "17.0", "UIDeviceFamily": [1], "UILaunchScreen": {},
                      "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]}, handle)
    sdk = run(XCRUN, "--sdk", "iphonesimulator", "--show-sdk-path", capture=True)
    architecture = run("uname", "-m", capture=True)
    run(XCRUN, "swiftc", "-sdk", sdk, "-target", f"{architecture}-apple-ios17.0-simulator",
        "-swift-version", "6", "-warnings-as-errors", "-parse-as-library", "-module-name", "SwiftCNVisualHost",
        *map(str, sorted((REPO / "Sources/SwiftCN").glob("*.swift"))),
        str(REPO / "Examples/iOSVisualHost/VisualHost.swift"), "-o", str(app / "SwiftCNVisualHost"),
        env=dict(os.environ, SDKROOT=sdk))
    run("/usr/bin/codesign", "--force", "--sign", "-", str(app))
    runtimes = json.loads(run(XCRUN, "simctl", "list", "runtimes", "-j", capture=True))["runtimes"]
    sdk_version = run(XCRUN, "--sdk", "iphonesimulator", "--show-sdk-version", capture=True)
    runtime = os.environ.get("SWIFTCN_IOS_RUNTIME")
    if not runtime:
        matching = [r for r in runtimes if r.get("isAvailable") and r["name"].startswith("iOS ")
                    and r["version"] == sdk_version]
        if not matching:
            raise RuntimeError(f"No available iOS runtime matches SDK {sdk_version}")
        runtime = matching[0]["identifier"]
    if args.profile == "ci" and runtime != "com.apple.CoreSimulator.SimRuntime.iOS-18-5":
        raise RuntimeError("The ci profile requires the iOS 18.5 runtime")
    device = run(XCRUN, "simctl", "create", "swiftcn-visual-tests",
                 "com.apple.CoreSimulator.SimDeviceType.iPhone-16", runtime, capture=True)
    try:
        print("Booting the dedicated visual simulator", flush=True)
        run(XCRUN, "simctl", "boot", device)
        run(XCRUN, "simctl", "bootstatus", device, "-b", capture=True, timeout=300)
        print("Booted the dedicated visual simulator", flush=True)
        run(XCRUN, "simctl", "install", device, str(app))
        container = Path(run(XCRUN, "simctl", "get_app_container", device, bundle_id, "data", capture=True))
        ready = container / "Documents/visual-ready"
        for scene in ["controls", "rules"]:
            for dark, large in [(False, False), (True, False), (False, True), (True, True)]:
                ready.unlink(missing_ok=True)
                flags = (["--rules"] if scene == "rules" else []) + (["--dark"] if dark else []) + (["--large-text"] if large else [])
                run(XCRUN, "simctl", "launch", "--terminate-running-process", device, bundle_id, *flags, timeout=120)
                deadline = time.monotonic() + 30
                while not ready.exists():
                    if time.monotonic() > deadline:
                        raise RuntimeError("The visual host did not signal readiness")
                    time.sleep(0.1)
                name = f"{scene}-{'dark' if dark else 'light'}-{'large-text' if large else 'standard'}"
                shutil.copyfile(container / "Documents/visual-snapshot.png", artifacts / f"{name}.png")
                print(f"Captured {name}", flush=True)
    finally:
        # Delete only the simulator created by this run.
        subprocess.run([XCRUN, "simctl", "shutdown", device], check=False)
        run(XCRUN, "simctl", "delete", device)
    references = (REPO / "Tests/SwiftCNVisualTests/__Snapshots__/ios-18.5-iphone-16"
                  if args.profile == "ci" else REPO / "artifacts/ios-local-baselines")
    references.mkdir(parents=True, exist_ok=True)
    environment = dict(os.environ, SWIFTCN_IOS_SCREENSHOTS=str(artifacts),
                       SWIFTCN_VISUAL_MODE=args.mode, SWIFTCN_SNAPSHOT_DIRECTORY=str(references),
                       SNAPSHOT_ARTIFACTS=str(REPO / "artifacts/visual-diffs"),
                       SDKROOT=run(XCRUN, "--sdk", "macosx", "--show-sdk-path", capture=True))
    run(XCRUN, "swift", "test", "--sdk", environment["SDKROOT"], "--filter", "IOSVisualTests", cwd=REPO, env=environment)


if __name__ == "__main__":
    main()
