# Visual testing

The visual suite uses Point-Free SnapshotTesting with native `NSHostingView` hosts.
The host renders AppKit controls, including text fields, toggles, and sliders.
The library has no runtime dependency on SnapshotTesting.

## Coverage

The macOS suite compares 34 reference images:

- Four scenes: buttons, native controls, utilities, and global rules.
- Two themes: light and dark.
- Two widths: 320 and 720 points.
- Two text-size environments: large and accessibility3.
- Two additional control scenes with right-to-left layout.

Button scenes cover rest, hover, focus, press, and disabled appearances.
The state previews use explicit state values for repeatable rendering.
Native buttons also cover typed styles, string styles, and the disabled environment.
Global scenes cover custom tokens, named classes, local overrides, subtree overrides, and sibling isolation.
Animation classes appear in native buttons, state previews, and custom global rules on both platforms.
These images check their static appearances against the existing references.

Hosted behavior tests check native interpolation during state entry and exit.
They cover computed strings, state variants, child identity, transaction scope, and disabled transactions.
The resolver tests check Reduce Motion, timing, and custom presets.
The image suite does not compare intermediate animation frames.

Shared element tests measure the rendered size of a native follower with a typed ID.
They check matching within one namespace and isolation between namespaces.
Class tests also cover local groups, nested groups, named ancestor selection, and sibling isolation.
Hosted tests verify that group updates preserve the native namespace and child state.
Parser tests cover group variants, composed conditions, and invalid IDs.

Argument tests compare bracket classes with equivalent native modifiers at exact pixels.
They cover both themes and both text-size environments.
Tests also check inherited text attributes, child identity, custom factories, and invalid arguments.
CI uploads both native and class images for review.
The Arguments demo exports both themes and includes a live class editor.

Container animation tests cover string and typed presets, custom rules, child identity, and disabled transactions.
The catalog exports both shared element layouts in light and dark mode.
CI uploads these exports and the follower images as visual evidence.

macOS controls can ignore the text-size environment.
These images check rendering under that environment; they do not prove iOS Dynamic Type behavior.

The iOS suite captures eight screenshots from a dedicated iPhone 16 simulator.
It covers native controls and global rules in both themes with standard and accessibility3 text sizes.
The host uses iOS 18.5 in CI.
The capture script waits for the host to signal readiness.
The host captures its native view hierarchy and excludes system status icons and the Dynamic Island.
The script deletes its own simulator after each run.

Native pointer, touch, and keyboard tests use the component gallery application host.
See [interaction testing](interaction-testing.md) for local commands and CI coverage.
VoiceOver and physical-device behavior still require separate checks.

## Local workflow

Local references use `artifacts/local-baselines`.
They stay separate from committed references because macOS versions can produce different pixels.
The iOS script selects the installed runtime that matches the selected Xcode SDK by default.
Set `SWIFTCN_IOS_RUNTIME` to choose another installed runtime for local comparisons.
Record the local references before the first comparison:

```bash
bash Scripts/visual-test.sh record local
bash Scripts/visual-test.sh verify local
python3 Scripts/ios-visual-test.py record local
python3 Scripts/ios-visual-test.py verify local
```

Run the native behavior tests separately:

```bash
swift test --skip SwiftCNVisualTests
```

Use `record` only when you intend to replace the selected references.
Run `verify` during normal development.
The comparison uses exact pixels.
Verification fails when a reference is missing or differs.
Verification never creates or replaces a reference.

Failure images appear in `artifacts/visual-diffs`.
Each failure includes the reference, the new image, and their difference.

## Continuous integration

The continuous integration (CI) job selects macOS 15 and Xcode 16.4.
The committed macOS references use `Tests/SwiftCNVisualTests/__Snapshots__/macos-15-xcode-16.4`.
The iOS references use `Tests/SwiftCNVisualTests/__Snapshots__/ios-18.5-iphone-16`.
The normal CI job verifies these references on each main push and pull request.
The job uploads visual evidence even when verification fails.

The hosted macOS image enables Reduce Motion.
The behavior step turns it off to check native interpolation.
The step restores the previous setting before image comparisons.
Local behavior tests respect the current accessibility setting and check suppression when Reduce Motion is on.

GitHub updates runner images over time.
A runner update can change native pixels without a source change.
Check the runner version before accepting a new reference after an unexpected failure.

## Update committed references

1. Push the intended source changes to a branch whose name starts with `visual-baselines/`.

2. Open the `Record visual baselines` workflow in GitHub Actions.

3. Download the `swiftcn-baseline-candidates` artifact after the workflow passes.

4. Inspect all changed images.

5. Copy the reviewed candidate images into their committed reference directories.

6. Commit the reference changes with the source changes.

7. Run the normal CI verification.

The recording workflow records candidates and verifies them in a second test process.
It never commits or approves candidate images automatically.
You can also start that workflow manually for a selected branch.
