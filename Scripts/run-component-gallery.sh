#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
export SDKROOT="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
/usr/bin/xcrun swift build --sdk "$SDKROOT" --package-path "$repo_dir" --product SwiftCNComponentGallery
bin_dir="$(/usr/bin/xcrun swift build --sdk "$SDKROOT" --package-path "$repo_dir" --show-bin-path)"
app_dir="$repo_dir/artifacts/SwiftCN Component Gallery.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$bin_dir/SwiftCNComponentGallery" "$app_dir/Contents/MacOS/SwiftCNComponentGallery"
python3 - "$app_dir" <<'PY'
import plistlib,sys
from pathlib import Path
with (Path(sys.argv[1])/'Contents/Info.plist').open('wb') as file:
    plistlib.dump(dict(CFBundleExecutable='SwiftCNComponentGallery',CFBundleIdentifier='dev.swiftcn.component-gallery',
                      CFBundleName='SwiftCN Component Gallery',CFBundlePackageType='APPL',CFBundleShortVersionString='0.1.0',
                      CFBundleVersion='1',LSMinimumSystemVersion='14.0',NSHighResolutionCapable=True,NSPrincipalClass='NSApplication'),file)
PY
/usr/bin/codesign --force --sign - "$app_dir"
/usr/bin/open "$app_dir"
echo "Opened $app_dir"
