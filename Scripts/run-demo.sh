#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
catalog_dir="$repo_dir/Examples/Catalog"
export SDKROOT="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
/usr/bin/xcrun swift build --sdk "$SDKROOT" --package-path "$catalog_dir"
bin_dir="$(/usr/bin/xcrun swift build --sdk "$SDKROOT" --package-path "$catalog_dir" --show-bin-path)"
app_dir="$repo_dir/artifacts/SwiftCN Demo.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$bin_dir/SwiftCNCatalog" "$app_dir/Contents/MacOS/SwiftCNCatalog"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>SwiftCNCatalog</string>
    <key>CFBundleIdentifier</key><string>dev.swiftcn.demo</string>
    <key>CFBundleName</key><string>SwiftCN Demo</string>
    <key>CFBundleDisplayName</key><string>swiftcn Demo</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign - "$app_dir"
/usr/bin/open "$app_dir"
echo "Opened $app_dir"
