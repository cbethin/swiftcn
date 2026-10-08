# Native interaction tests

The UI suite uses XCTest and Apple's XCUIAutomation.
It launches the component gallery as an application and sends native mouse, keyboard, and touch input.
Swift Testing continues to check models, parsing, layout constraints, state, and native view identity.
SnapshotTesting continues to compare rendered images.

## Run locally

Install XcodeGen and select an Xcode installation with a matching simulator runtime.

```bash
brew install xcodegen
bash Scripts/interaction-test.sh macos
bash Scripts/interaction-test.sh ios
SWIFTCN_UI_DEVICE_FAMILY=iPad bash Scripts/interaction-test.sh ios
```

The macOS tests control a separate gallery application.
Keep its windows visible during the run.
If its runner hangs before connecting, check Developer Tools authentication with `/usr/sbin/DevToolsSecurity -status`.
Enabling it requires local administrator approval: `sudo /usr/sbin/DevToolsSecurity -enable`.
The script does not change this permission.
The generated test schemes launch without an attached debugger; select a debugger in Xcode when needed.
The iOS script creates, boots, and deletes its own simulator.
It does not reset your existing simulators.

To use an existing simulator, pass its destination explicitly.
The script leaves that simulator installed and running.

```bash
SWIFTCN_UI_DESTINATION='platform=iOS Simulator,id=YOUR-SIMULATOR-UDID' \
  bash Scripts/interaction-test.sh ios
```

Pass normal `xcodebuild` test arguments after the platform to run a focused test.

```bash
bash Scripts/interaction-test.sh macos \
  -only-testing:InteractionTestsMac/GalleryInteractionTests/testNativeSplitDividerDragsWithoutLosingTheEditorDraft
```

Open the generated `Examples/Components/SwiftCNInteractions.xcodeproj` to run or debug tests in Xcode.
The checked-in `project.yml` is the project source.
The generated project stays outside Git.

## Coverage

The initial suite checks these workflows on macOS, iPhone, and iPad:

- Click the checkbox label and empty trailing space. Check the resulting value.
- Repeatedly open and close the dropdown. Invoke one action and reopen it.
- Open the date picker's calendar, choose a day, and check the formatted input. Reopen and close the popup.
- Edit a dialog field. Keep Close reachable above the software keyboard. Dismiss and reopen the dialog. Check the retained draft.
- Drag the custom resize handle in both directions. Check actual handle movement.

The macOS suite also checks native split and navigation dividers.
It sends pointer drags, checks the resulting pane movement, and edits the retained text view.
It checks native sidebar hide and show actions.
The dialog test checks Escape dismissal and keyboard reopening through restored focus.
The date-picker test also types a date and checks that opening the calendar commits it.

The tests launch real examples through a debug-only `SWIFTCN_UI_EXAMPLE` route.
This selects an initial gallery screen; it does not replace controls, gestures, or state changes.
The tested application imports the local SwiftCN package.
Tests wait for visible state with bounded expectations instead of fixed sleeps.
Retries and parallel UI execution remain off.

## Review failures

Each run writes a unique directory under `artifacts/interactions`.
It contains the build log, `results.xcresult`, and a JSON test summary when available.
Open the result bundle in Xcode to inspect screenshots and the action trace.
Screenshot attachments remain available for successful tests too.

CI runs separate macOS, iPhone, and iPad jobs on Xcode 16.4.
Each job uploads its result directory even after failure.
The UI suite does not change screenshot references or retry failures until they pass.

These tests cover native input in a desktop session or simulator.
They do not verify physical-device touch, VoiceOver traversal, every component workflow, or Duo fold transitions.
Keep those checks separate from these results.
