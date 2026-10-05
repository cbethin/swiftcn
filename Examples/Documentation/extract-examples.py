#!/usr/bin/env python3
"""Extract complete documentation examples; fail if a required example disappears."""

import re
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
output = Path(sys.argv[1])
output.mkdir(parents=True, exist_ok=True)
expected = {
    "installation": {"Package.swift"},
    "quick-start": {"ContentView.swift", "SwiftCNDemoApp.swift"},
    "native-controls": {"FocusExample.swift"},
    "troubleshooting": {"StyleValidation.swift"},
}
pattern = re.compile(r'^```swift title="([^"\n]+\.swift)"\n(.*?)^```\s*$', re.M | re.S)
seen = set()
for page, required in expected.items():
    source = repo / "website/content/docs" / f"{page}.mdx"
    examples = pattern.findall(source.read_text())
    found = {name for name, _ in examples}
    if found != required:
        raise SystemExit(f"{source}: expected {sorted(required)}, found {sorted(found)}")
    for name, code in examples:
        if name != Path(name).name or name in seen:
            raise SystemExit(f"Duplicate or invalid documentation example filename: {name}")
        seen.add(name)
        (output / name).write_text(code)
print(f"Extracted {len(seen)} complete Swift examples from the documentation.")
