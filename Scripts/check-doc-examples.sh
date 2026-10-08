#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/swiftcn-doc-examples.XXXXXX")"
trap 'rm -rf "$scratch_dir"' EXIT
compiler_path="$(/usr/bin/xcrun --find swiftc)"
machine_arch="$(uname -m)"

python3 "$repo_dir/Examples/Documentation/extract-examples.py" "$scratch_dir/examples"
mkdir -p "$scratch_dir/manifest/Sources/ProjectUI"
cp "$scratch_dir/examples/Package.swift" "$scratch_dir/manifest/Package.swift"
printf 'public struct Placeholder {}\n' > "$scratch_dir/manifest/Sources/ProjectUI/Placeholder.swift"
/usr/bin/xcrun swift package --package-path "$scratch_dir/manifest" dump-package > "$scratch_dir/manifest.json"

mkdir -p "$scratch_dir/owned/Sources" "$scratch_dir/consumer" "$scratch_dir/core" "$scratch_dir/component-copy"
cp "$repo_dir"/Sources/SwiftCN/*.swift "$scratch_dir/core/"
cp "$repo_dir"/Sources/SwiftCN/*.swift "$scratch_dir/owned/Sources/"
cp "$repo_dir/LICENSE" "$scratch_dir/owned/LICENSE"
python3 - "$scratch_dir" <<'PY'
from pathlib import Path
import json
import sys

scratch = Path(sys.argv[1])
manifest = json.loads((scratch / 'manifest.json').read_text())
assert manifest['name'] == 'ProjectUI', 'Documentation package name changed.'
product = manifest['targets'][0]['dependencies'][0]['product']
assert product[:2] == ['SwiftCN', 'swiftcn'], 'Documentation must import the SwiftCN product.'
for example in (scratch / 'examples').glob('*.swift'):
    if example.name == 'Package.swift':
        continue
    code = example.read_text()
    (scratch / 'consumer' / example.name).write_text(code)
    (scratch / 'owned/Sources' / example.name).write_text(
        code.replace('import SwiftCN\n', '')
    )
PY
python3 - "$repo_dir" "$scratch_dir" <<'PYTHON'
from pathlib import Path
import json, sys
repo, scratch = map(Path, sys.argv[1:])
catalog = json.loads((repo/'Components/catalog.json').read_text())
for filename in {entry['source'] for entry in catalog}:
    source = repo/'website/public/registry'/filename
    (scratch/'component-copy'/filename).write_bytes(source.read_bytes())
for entry in catalog:
    (scratch/'component-copy'/entry['example']).write_bytes((scratch/'consumer'/entry['example']).read_bytes())
for entry in json.loads((repo/'Components/native-examples.json').read_text()):
    (scratch/'component-copy'/entry['example']).write_bytes((scratch/'consumer'/entry['example']).read_bytes())
(scratch/'component-copy'/'MixedComponentOptions.swift').write_bytes(
    (repo/'Tests/SourceOwnership/MixedComponentOptions.swift').read_bytes())
(scratch/'component-copy'/'MixedDropdownParts.swift').write_bytes(
    (repo/'Tests/SourceOwnership/MixedDropdownParts.swift').read_bytes())
(scratch/'component-copy'/'MixedSidebarParts.swift').write_bytes(
    (repo/'Tests/SourceOwnership/MixedSidebarParts.swift').read_bytes())
(scratch/'component-copy'/'MixedPresentationParts.swift').write_bytes(
    (repo/'Tests/SourceOwnership/MixedPresentationParts.swift').read_bytes())
PYTHON
cmp "$repo_dir/LICENSE" "$scratch_dir/owned/LICENSE"

for sdk in macosx iphonesimulator; do
    sdk_dir="$(/usr/bin/xcrun --sdk "$sdk" --show-sdk-path)"
    if [[ "$sdk" == "macosx" ]]; then
        target="$machine_arch-apple-macosx14.0"
    else
        target="$machine_arch-apple-ios17.0-simulator"
    fi
    output_dir="$scratch_dir/$sdk"
    mkdir -p "$output_dir"
    "$compiler_path" -sdk "$sdk_dir" -target "$target" \
        -swift-version 6 -warnings-as-errors -parse-as-library \
        -module-name SwiftCN -emit-module -emit-module-path "$output_dir/SwiftCN.swiftmodule" \
        "$scratch_dir"/core/*.swift
    "$compiler_path" -sdk "$sdk_dir" -target "$target" \
        -swift-version 6 -warnings-as-errors -parse-as-library -I "$output_dir" \
        -module-name DocumentationConsumer -emit-module \
        -emit-module-path "$output_dir/DocumentationConsumer.swiftmodule" \
        "$scratch_dir"/consumer/*.swift
    "$compiler_path" -sdk "$sdk_dir" -target "$target" \
        -swift-version 6 -warnings-as-errors -parse-as-library \
        -module-name OwnedDocumentation -emit-module \
        -emit-module-path "$output_dir/OwnedDocumentation.swiftmodule" \
        "$scratch_dir"/owned/Sources/*.swift
    "$compiler_path" -sdk "$sdk_dir" -target "$target" \
        -swift-version 6 -warnings-as-errors -parse-as-library -I "$output_dir" \
        -module-name CopiedComponentDocumentation -emit-module \
        -emit-module-path "$output_dir/CopiedComponentDocumentation.swiftmodule" \
        "$scratch_dir"/component-copy/*.swift
    echo "Documentation examples compile for $target with imports and copied source."
done

echo "The complete package manifest is valid; copied sources retain the MIT license."
