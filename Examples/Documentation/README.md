# Documentation examples

The complete consumer examples live in the documentation's titled Swift code blocks.
They are the source for this check; this directory keeps no duplicate Swift examples.

Run from the repository root:

```bash
bash Scripts/check-doc-examples.sh
```

The script checks the installation manifest without fetching its remote dependency.
It extracts the quick-start app, native focus view, and diagnostic helper from MDX.
It compiles them with Swift 6 and warnings as errors for macOS 14 and the iOS 17 simulator.

Each platform checks two ways to consume the library:

- Import the separate SwiftCN module.
- Copy the complete runtime source into the consumer module and remove its imports.

The copied-source check retains and compares the MIT license.
Temporary files remain isolated from the repository's SwiftPM build directories.
This compiler check does not launch the app or replace native visual and behavior tests.
