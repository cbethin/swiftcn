# Native styles and component composition

Status: Implementation. The package includes the APIs and recipes below.
The component gallery includes four complete native composition examples.

## Design rule

SwiftUI owns control behavior, bindings, focus, navigation, and native presentation.
Swiftcn owns visual recipes and composable content parts.
Keep bindings and callbacks as typed Swift arguments.
Use classes for appearance and supported motion settings.

Keep the current custom calendar, dropdown, command palette, and offcanvas sidebar.
Their layouts express a deliberate design.
Use native controls inside these layouts.

## Proposal 1: Make native styles a primary usage path

The package already provides `.buttonStyle(.tw(...))`, `.textFieldStyle(.tw(...))`, `.toggleStyle(.tw(...))`, and `.labelStyle(.tw(...))`.
Document these APIs beside the convenience components.
Use the same recipes in both paths.

This example uses existing APIs:

```swift
enum Field: Hashable { case amount }

@State private var amount = 0.0
@FocusState private var focusedField: Field?

TextField("Amount", value: $amount, format: .number)
    .textFieldStyle(.tw("input", state: .init(
        isFocused: focusedField == .amount
    )))
    .focused($focusedField, equals: .amount)
    .onSubmit(save)

Button("Delete", role: .destructive, action: delete)
    .buttonStyle(.tw("button-destructive"))
    .keyboardShortcut(.delete, modifiers: .command)

Toggle("Notifications", isOn: $notifications)
    .toggleStyle(.tw("switch", base: .switch))
```

The caller owns formatting and focus.
The style receives focus state for its appearance.
Do not infer a binding from a class string.

### Change scope

1. Add direct native examples to the input, button, switch, and field pages.

2. Reuse the native style adapters inside convenience components where their behavior matches.

3. Preserve padded activation surfaces until interaction checks confirm equivalent native activation.

4. Document `CNFieldControl` for controls without a matching SwiftUI style protocol.

### Acceptance checks

- Compile formatted fields with enum-based focus on iOS 17 and macOS 14.
- Verify submit handling, selection, paste, disabled state, and complete activation surfaces.
- Verify native switch dragging with a styled label row.
- Verify identical recipes through imported and copied components.

## Proposal 2: Separate Drawer content from presentation

Add `CNDrawerContent` as a content part.
The part applies the `drawer` recipe to a vertical stack.
It does not add scrolling, presentation hosts, detents, or a fixed frame.
The caller chooses these behaviors at the sheet root.

Usage:

```swift
@State private var open = false
@State private var detent = PresentationDetent.height(240)

Button("Activity") { open = true }
    .buttonStyle(.tw("button-outline"))
    .sheet(isPresented: $open, onDismiss: refreshActivity) {
        ScrollView {
            CNDrawerContent {
                CNDialogTitle("Activity")
                ActivityList()
                Button("Done") { open = false }
                    .buttonStyle(.tw("button-outline"))
            }
        }
        .presentationDetents([.height(240), .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
    }
```

The selected detent must belong to the supported detents.
Detent behavior follows the platform.
The caller adds nested presentation hosts when the content requires custom presentations.
The caller controls the sheet background and appearance.

Retain `CNDrawer` as the convenience component.
Add these typed arguments to its initializer:

```swift
detents: Set<PresentationDetent> = [.medium, .large]
selection: Binding<PresentationDetent>? = nil
onDismiss: (() -> Void)? = nil
```

Keep the existing `classes` and `contentClasses` arguments.
Use `CNDrawerContent` inside `CNDrawer`.
Keep the convenience component's scrolling, appearance, and nested presentation hosts.
Use a caller-owned sheet for further native configuration.

### Acceptance checks

- Verify detent changes from both the binding and native interaction.
- Verify the native dismissal callback and disabled interactive dismissal.
- Verify long content with caller-owned scrolling.
- Verify copied content inside a native sheet with imported child controls.

## Proposal 3: Offer native navigation composition

The current `CNSidebar` implements an icon rail and an offcanvas layout.
Keep those behaviors explicit.
Add a native navigation example beside this component.
Use `NavigationSplitView`, `List`, and `NavigationLink` directly.

Add `sidebar-list` and `sidebar-item-label` as visual recipes.
The recipes do not control column widths, navigation state, or row selection.

Usage with the new recipes:

```swift
NavigationSplitView(columnVisibility: $visibility) {
    List(projects, selection: $selectedID) { project in
        NavigationLink(value: project.id) {
            Label(project.name, systemImage: "folder")
                .labelStyle(.tw("sidebar-item-label"))
        }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .tw("sidebar-list")
} detail: {
    ProjectDetail(projectID: selectedID)
}
```

SwiftUI owns column visibility and compact navigation.
The native list owns selection and keyboard navigation.
Use label parts inside links; avoid nested action buttons.
Do not add another navigation state model.

### Acceptance checks

- Verify desktop selection and keyboard navigation.
- Verify compact navigation and the native back action.
- Verify column changes preserve caller-owned editor state.
- Verify native selected-row contrast in both appearances.

## Proposal 4: Use native desktop split views directly

Document `HSplitView` and `VSplitView` with existing `.tw` utilities.
Do not add a wrapper that only renames these containers.

This example uses existing styling APIs on macOS:

```swift
HSplitView {
    Inspector()
        .tw("min-w-[180] bg-surface")
    Editor()
        .tw("min-w-[320] bg-surface")
}
.tw("border rounded-lg")
```

SwiftUI owns divider interaction and native layout.
The existing `CNResizable` retains its explicit fraction binding and mobile gesture support.
Native split views do not expose an equivalent SwiftUI fraction binding.
Keep these as distinct choices.

### Acceptance checks

- Verify pointer resizing and minimum pane widths.
- Verify child scrolling and text selection during resizing.
- Verify disabled controls and caller-owned editor state.
- Verify geometry after window resizing.

## Shared recipes

All paths use the existing global rules.
The following example changes an existing recipe:

```swift
.twRules {
    $0.named["input"] = "h-10 px-3 rounded-lg border bg-surface text-foreground"
}
```

Keep recipe resolution in the current styling engine.
Preserve caller-specified modifier order.
Do not add another parser or a separate theme system.
Measure styled and unstyled controls during list scrolling.
Check body updates, allocations, and native view identity.

## Recommended implementation order

1. Document direct native styles and test their interaction contracts.

2. Add `CNDrawerContent` and the typed Drawer configuration.

3. Add native sidebar recipes and a navigation example.

4. Add native desktop split examples.

Use focused changes with native interaction checks and reviewed visual references.

## Native API references

- [Formatted TextField](https://developer.apple.com/documentation/swiftui/textfield/init(value:format:prompt:label:)-99ntf)
- [Sheet detent selection](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:selection:))
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [HSplitView](https://developer.apple.com/documentation/swiftui/hsplitview)
