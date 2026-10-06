# Native component catalog

## Scope

Cover all 64 entries in the referenced shadcn catalog.
Use original SwiftUI implementations and native platform behavior.
Keep the existing `SwiftCN` package product and `CN` component names.
Keep the current iOS 17 and macOS 14 deployment targets.

## Component contract

- Use `.tw` class recipes for colors, text, padding, borders, corners, shadows, and control tint.
- Use native layout containers for alignment and spacing.
- Expose bindings for selection, input, disclosure, presentation, and navigation state.
- Accept trailing class overrides and custom content through view builders.

- Keep native button roles, labels, keyboard actions, focus, and disabled behavior.
- Preserve stable data identifiers in collection components.
- Keep copied component source independent of private library helpers.
- Document the native behavior and platform differences for each component.

## Native foundations

| Family | Foundation |
| --- | --- |
| Buttons and toggles | Button, Toggle, Picker, native styles |
| Editors and dates | TextField, SecureField, TextEditor, DatePicker |
| Menus and presentation | Menu, contextMenu, alert, sheet, popover |
| Disclosure and navigation | DisclosureGroup, NavigationSplitView, TabView |
| Collections and layout | Table, Grid, ScrollView, LazyVStack, native split views |
| Feedback and charts | ProgressView, Swift Charts, native accessibility |
| Messages and questionnaires | Bound model values, native editors, stable rows |

## Source delivery

Create a catalog manifest with the component name, source files, native foundation, usage example, and platform notes.
Generate a documentation page for each catalog entry from that manifest.
Show complete copyable source on each page.
Provide a source bundle that includes the styling core and license.
Compile every usage example with package imports and copied source.
Check generated pages against their source files in continuous integration.

## Validation

Test binding changes, selection, disabled actions, focus, validation, dismissal, and collection identity.
Render every catalog entry in light and dark appearances.
Check narrow layouts and large text for representative component families.
Retain the existing macOS and iOS visual baselines.
Record new baselines in the correct platform profiles.

Compile the library and examples for macOS and iOS.
Build the documentation site and check search, source downloads, and local links.
Review the final implementation and open a pull request with the results.

## Design refinement

Use consistent spacing, typography, corners, borders, and control heights across related components.
Stack action rows when their content exceeds the available width.
Keep the same child controls when the layout changes.

Animate control feedback, disclosure layout, and temporary feedback with editable class recipes.
Respect Reduce Motion.
Keep drag tracking immediate and preserve native scrolling gestures.
Review native images in both appearances before accepting each reference.
