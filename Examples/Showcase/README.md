# SwiftCN Showcase

Four small apps share one launcher. Each app has its own theme and saves edits on the device.

| App | Workflows | SwiftCN components |
| --- | --- | --- |
| Daylight | Create tasks, complete tasks, filter projects, move or delete tasks | Checkbox, progress, input, date picker, badge |
| Ledger | Add, edit, delete expenses; view categories; set a budget | Chart, progress, field, input, date picker |
| Fieldnotes | Write, edit, search, star, and delete journal entries | Textarea, input group, buttons, fields |
| Roam | Create trips, change dates, add itinerary stops, track packing, delete trips | Date picker, checkbox, field, buttons |

Native SwiftUI owns navigation, tabs, menus, text editing, sheets, and confirmation dialogs.
SwiftCN supplies component styling through `.tw` and theme tokens.
Calendar popups use SwiftUI's native popover placement with SwiftCN's custom calendar content.
Background layers use `.ignoresSafeArea(.container)`. Foreground pages keep SwiftUI's native safe-area insets.
The sample data uses USD for Ledger amounts. These apps do not require network access.

## Adaptive layouts

Partially fold Duo like a book to place the collection and detail on opposite sides of the hinge.
Open Duo flat to use the normal sidebar layout.
Close Duo to keep the selected item in a single navigation stack.
Use the native Back button to return to the collection.

| App | Split view example |
| --- | --- |
| Daylight, Projects tab | Project collection beside its tasks |
| Ledger, Activity tab | Transactions beside amounts and budget context |
| Fieldnotes | Notebook beside a selected journal page |
| Roam | Journeys beside itinerary and packing controls |

Each screen uses `NavigationSplitView` and native `List` selection.
Keep column widths unconstrained so SwiftUI can align both panes with the fold.
A narrow maximum sidebar width prevents this native adaptation.
See [Apple’s adaptive layout guide](https://developer.apple.com/videos/play/tech-talks/111463/).
Selection uses item IDs. Folding does not replace the selected item or reset its local state.
The wider layout selects an initial item when no item is selected.
No device model checks, screen dimensions, or custom navigation router are required.

Editors attach `sourceSheet` to the trigger button. `DemoRoot` installs `sheetSourceSpace` once.
On iOS 27, the helper uses the trigger's window position and native `.presentationPlacement` to choose its side.
The active vertical fold defines the boundary. Otherwise, the window midpoint defines it.
SwiftUI still owns sheet dragging, keyboard avoidance, dismissal, and compact layouts.
Older systems use automatic native placement. `SourceSheet.swift` contains the helper.

## Run

Install XcodeGen, then run from the repository root:

```sh
python3 Scripts/run-showcase.py
```

Use Xcode 27.1 and the iOS 27.1 runtime for the actual iPhone Duo simulator:

```sh
DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer python3 Scripts/run-showcase.py --duo
```

Add `--test` to run native workflow tests before launch:

```sh
DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer python3 Scripts/run-showcase.py --duo --test
```

Apple lists Xcode 27.1 as the supported Duo toolchain. Xcode 27.2 beta still directs Duo work to Xcode 27.1.
See [Apple’s release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes).
An iOS 27.0 SDK build uses Duo's compatibility layout, which excludes the right status area.
The 27.1 SDK enables the full-screen layout and adaptive native bars. See [Apple’s preparation guide](https://developer.apple.com/videos/play/tech-talks/111461/).

The script preserves the dedicated simulator and leaves the app running.
Use `--viewer /path/to/DeviceHub.app` to open another installed viewer while keeping the selected build SDK.
An older viewer can display the app but does not expose Duo's hinge controls.
Build logs, device details, and test result bundles live in `artifacts/showcase`.
Tests use a separate preferences domain. They do not clear the demo's user data.

## Change the design

Edit `ShowcaseStyle.swift` to change the four `TWTheme` values and the shared surfaces.
Edit each app file to change its screens. No custom routing framework is needed.
`ShowcaseStore.swift` contains the seed data and the Codable snapshot stored in UserDefaults.
This persistence is suitable for the demo's small data set. It is not a database or a sync service.
