#!/usr/bin/env python3
"""Capture a dedicated iPhone simulator and compare reviewed image references."""
import argparse
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import time
import uuid

REPO = Path(__file__).resolve().parent.parent
XCRUN = "/usr/bin/xcrun"


def run(*args, capture=False, **kwargs):
    result = subprocess.run(args, check=True, text=True, capture_output=capture, **kwargs)
    return result.stdout.strip() if capture else None


class CaptureReadinessTimeout(RuntimeError):
    pass


def launch_capture(device, bundle_id, flags, ready, artifacts, name):
    (artifacts / f"{name}-launch.log").write_text("")
    for attempt in range(2):
        try:
            launch_capture_attempt(device, bundle_id, flags, ready, artifacts, name, attempt)
            return
        except CaptureReadinessTimeout:
            if attempt == 1:
                raise
            print(f"Retrying {name} after the simulator did not render its readiness marker", flush=True)


def launch_capture_attempt(device, bundle_id, flags, ready, artifacts, name, attempt):
    # The host's per-launch marker proves rendering finished, even if simctl has not returned.
    capture_id = uuid.uuid4().hex
    command = [XCRUN, "simctl", "launch", "--terminate-running-process", device, bundle_id,
               *flags, "--capture-id", capture_id]
    log = artifacts / f"{name}-launch.log"
    with log.open("a") as output:
        output.write(f"Capture attempt {attempt + 1}: {capture_id}\n")
        output.flush()
        process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT, text=True)
        try:
            deadline = time.monotonic() + 120
            while True:
                if ready.exists() and ready.read_text() == capture_id:
                    return
                status = process.poll()
                if status is not None and status != 0:
                    raise RuntimeError(f"Simulator launch failed with status {status}; see {log}")
                if time.monotonic() > deadline:
                    raise CaptureReadinessTimeout(f"The visual host did not signal readiness for {name}; see {log}")
                time.sleep(0.1)
        finally:
            if process.poll() is None:
                # Stop only our launch command. The simulator and app stay alive for the next capture.
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["record", "verify"], nargs="?", default="verify")
    parser.add_argument("profile", choices=["local", "ci"], nargs="?", default="local")
    parser.add_argument("--components", action="store_true", help="Capture all 64 component examples")
    parser.add_argument("--only", nargs="+", metavar="SLUG", help="Capture selected component slugs for a focused review")
    args = parser.parse_args()
    if args.only:
        if not args.components:
            parser.error("--only requires --components")
        catalog_slugs = {entry["slug"] for entry in json.loads((REPO / "Components/catalog.json").read_text())}
        unknown = set(args.only) - catalog_slugs
        if unknown:
            parser.error("Unknown component slugs: " + ", ".join(sorted(unknown)))
    if args.profile == "ci":
        sdk_version = run(XCRUN, "--sdk", "iphonesimulator", "--show-sdk-version", capture=True)
        if sdk_version != "18.5" or "Xcode 16.4" not in run("/usr/bin/xcodebuild", "-version", capture=True):
            raise RuntimeError("The ci profile requires Xcode 16.4 with iOS 18.5. Use the local profile.")
    artifacts = REPO / "artifacts" / ("ios-components" if args.components else "ios-visual")
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
    # Freeze inputs. Components use public package APIs; the visual host owns a source copy.
    with tempfile.TemporaryDirectory(prefix="swiftcn-ios-capture-") as temporary:
        frozen = Path(temporary)
        sources = list((REPO / "Sources/SwiftCN").glob("*.swift"))
        sources += list((REPO / "Examples/Components/Sources").glob("*Example.swift"))
        sources += [REPO / "Examples/Components/Sources/ComponentGallery.swift", REPO / "Examples/iOSVisualHost/VisualHost.swift"]
        for source in sources:
            (frozen/source.name).write_text(source.read_text().replace("import SwiftCN\n", ""))
        run(XCRUN, "swiftc", "-sdk", sdk, "-target", f"{architecture}-apple-ios17.0-simulator",
            "-swift-version", "6", "-warnings-as-errors", "-parse-as-library", "-module-name", "SwiftCNVisualHost",
            *map(str, sorted(frozen.glob("*.swift"))), "-o", str(app / "SwiftCNVisualHost"),
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
        captures = []
        if args.components:
            catalog = json.loads((REPO / "Components/catalog.json").read_text())
            narrow = {"field", "input-group", "message", "questionnaire", "empty", "card", "radio-group", "typography", "pagination", "sidebar", "skeleton", "spinner", "table"}
            for entry in catalog:
                if args.only and entry['slug'] not in args.only:
                    continue
                for dark, large in [(False, False), (True, False)] + ([(False, True)] if entry['slug'] in narrow else []):
                    flags = ["--component", entry['slug'].replace('-', '_')] + (["--dark"] if dark else []) + (["--large-text"] if large else [])
                    name = f"component-{entry['slug']}-{'dark' if dark else 'light'}-{'large-text' if large else 'standard'}"
                    captures.append((flags, name))
        else:
            for scene in ["controls", "rules"]:
                for dark, large in [(False, False), (True, False), (False, True), (True, True)]:
                    flags = (["--rules"] if scene == "rules" else []) + (["--dark"] if dark else []) + (["--large-text"] if large else [])
                    captures.append((flags, f"{scene}-{'dark' if dark else 'light'}-{'large-text' if large else 'standard'}"))
        for flags, name in captures:
            ready.unlink(missing_ok=True)
            launch_capture(device, bundle_id, flags, ready, artifacts, name)
            shutil.copyfile(container / "Documents/visual-snapshot.png", artifacts / f"{name}.png")
            print(f"Captured {name}", flush=True)
    finally:
        # Delete only the simulator created by this run.
        subprocess.run([XCRUN, "simctl", "shutdown", device], check=False)
        run(XCRUN, "simctl", "delete", device)
    references = (REPO / ("Tests/SwiftCNVisualTests/__Snapshots__/components-ios-18.5-iphone-16" if args.components else "Tests/SwiftCNVisualTests/__Snapshots__/ios-18.5-iphone-16")
                  if args.profile == "ci" else REPO / ("artifacts/ios-component-baselines" if args.components else "artifacts/ios-local-baselines"))
    references.mkdir(parents=True, exist_ok=True)
    environment = dict(os.environ, SWIFTCN_IOS_SCREENSHOTS=str(artifacts),
                       SWIFTCN_VISUAL_MODE=args.mode, SWIFTCN_SNAPSHOT_DIRECTORY=str(references),
                       SNAPSHOT_ARTIFACTS=str(REPO / "artifacts/visual-diffs"),
                       SDKROOT=run(XCRUN, "--sdk", "macosx", "--show-sdk-path", capture=True))
    if args.components: environment["SWIFTCN_IOS_COMPONENT_SCREENSHOTS"] = str(artifacts)
    environment.pop("SWIFTCN_IOS_COMPONENT_SELECTION", None)
    if args.only: environment["SWIFTCN_IOS_COMPONENT_SELECTION"] = ",".join(args.only)
    run(XCRUN, "swift", "test", "--sdk", environment["SDKROOT"], "--filter", "IOSComponentVisualTests" if args.components else "IOSVisualTests", cwd=REPO, env=environment)


if __name__ == "__main__":
    main()
