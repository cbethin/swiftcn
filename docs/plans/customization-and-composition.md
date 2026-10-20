# Customization and composition interface

Status: implemented. The gallery uses these APIs for its appearance choices, workspace choices, and settings.

## Purpose

Keep simple controls short to write. Keep complete control over appearance, content, and native behavior.
Extend the current themes, recipes, classes, and SwiftUI content builders.

## 1. Keep local customization

Keep the existing component initializers and class strings.
Keep typed `TWStyle` utilities for native style adapters.

```swift
CNButton("Save", classes: "rounded-lg px-6", action: save)

Button("Save", action: save)
    .buttonStyle(.tw(.primaryButton, .radius(10), .px(6)))
```

Local classes change only this instance.
Ordinary SwiftUI modifiers remain available.
An appearance change does not replace a binding, action, role, or content builder.

## 2. Add reusable rule overrides

Add `TWRuleOverrides` and `.twRules(overrides:)`.
An override stores only declared changes. It does not copy the standard registries into its stored values.

```swift
static let workbench = TWRuleOverrides(
    named: [
        "button-ghost": "rounded-lg",
        "card": "shadow-none",
        "segmented-indicator": "bg-surface border shadow-sm"
    ]
)

WorkbenchView()
    .twRules(overrides: Self.workbench)
```

Each `named` entry extends the inherited recipe. Unchanged properties keep their inherited values.
Nested scopes extend the nearest parent scope. They preserve unrelated recipes and registries.
The engine combines the actual parent definition with the override. It does not create a recursive class reference.

Use `replacing` to replace a complete recipe explicitly.

```swift
static let customChrome = TWRuleOverrides(
    replacing: [
        "button-ghost": "px-2 min-h-[32] text-foreground rounded-md"
    ]
)
```

Reject a recipe name that occurs in both dictionaries.
Keep the existing `.twRules(rules)` method for replacing the complete environment.
Keep the existing mutation closure for advanced uses.

Accept `TWStyle` values in both dictionaries. String literals and typed utilities use the same engine.
Allow explicit animation, utility, and native modifier entries through the corresponding override fields.
Merge those registries by name. Replace a conflicting registry entry instead of composing its implementation.

Append the override's `view` and `button` styles to the inherited defaults.
Cache the combined rules by the parent revision and override revision.
Reuse the revision while the declared override remains unchanged.

## 3. Make recipe precedence predictable

Apply recipe layers in this order:

1. Apply the built-in component recipes.

2. Apply the app overrides.

3. Apply the nested scope overrides.

4. Apply the instance classes.

Compare these layers within the same state and specificity.
Keep the existing state precedence for hover, focus, press, and disabled appearance.
Keep disabled appearance above other interaction states.

Move visual defaults out of component wrappers and into recipes.
Do not append hidden padding, color, or radius overrides after the recipe.
Keep structural layout and native behavior inside the component.
Preserve current component appearance when moving these defaults.

Keep the existing recipe names for existing components.
Use named parts when a component has separate styled surfaces.
For a segmented control, expose `segmented`, `segmented-item`, and `segmented-indicator` recipes.
Do not add a separate styling language for parts.

## 4. Share control metrics through the theme

Add `TWTheme.controls` with platform defaults for each supported SwiftUI control size.
Each entry contains minimum height, horizontal padding, vertical padding, icon width, and radius.
Keep these values editable.

```swift
var theme = TWTheme.standard
theme.controls.small.minHeight = 32
theme.controls.small.radius = 8

WorkbenchView()
    .twTheme(theme)
    .controlSize(.small)
```

Use the native SwiftUI `.controlSize` environment instead of adding another density modifier.
Let styled controls read the corresponding theme metrics.
Keep `CNButton(size:)` as an explicit local convenience.
An explicit component size takes precedence over the inherited control size.
An omitted size follows the inherited control size.
Use instance classes for a final dimension override.

Native switch indicators retain their native sizing policy.
Preserve minimum platform hit targets when a theme requests smaller metrics.
Allow text growth to increase the control height.

## 5. Add selection styling and a segmented control

Add `TWState.isSelected`, `selected:` classes, and the typed `.selected(...)` utility.
Selection styling does not change the underlying selection.
Controls supply selection state from their existing bindings.
General styled views receive explicit selection state from the caller.

```swift
CNToggle("Bold", isOn: $bold,
         classes: "selected:bg-primary selected:text-onPrimary")
```

Apply selected styles before hover, focus, press, and disabled styles.
Support nested conditions such as `selected:hover:bg-primary`.
Keep the standard selected surface steady during hover.
Components retain their native accessibility state.

Add `CNSegmentedControl` and `CNSegment` as a controlled single-selection composition.
Use explicit values and generic label builders.

```swift
CNSegmentedControl(selection: $mode) {
    CNSegment(WorkspaceMode.preview) {
        Label("Preview", systemImage: "rectangle.on.rectangle")
    }
    CNSegment(WorkspaceMode.code) {
        Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
    }
    CNSegment(WorkspaceMode.split) {
        Label("Split", systemImage: "rectangle.split.2x1")
    }
}
```

Keep the binding in the caller. Keep the selected content outside the selection control.
Support keyboard navigation, focus, disabled segments, and accessible selection.
Use the named recipes to customize the group, each segment, and the selected indicator.
Keep animated indicator movement optional and compatible with Reduce Motion.

## 6. Extend existing content builders

Add a label builder to `CNToggleGroup`.
Pass each existing `CNOption` to the builder.
Keep its identifier and disabled state in the option.

```swift
CNToggleGroup(options, selection: $selection) { option in
    HStack {
        Text(option.title)
        if option.id == "design" {
            CNBadge("New")
        }
    }
}
```

Keep the current text convenience initializer.
Add equivalent custom label support to sidebar rows.
Let SwiftUI builders supply content instead of adding many icon, badge, and subtitle parameters.

## Integration and verification

The gallery uses inherited overrides for its chrome.
The appearance choices and workspace choices use the segmented control.
Settings use the same components and shared metrics.
The catalog includes a segmented control example.
The documentation includes a complete customization example.

The source checks compile imported components, copied components, and mixed segment parts.
Hosted tests check keyboard navigation in both layout directions.
Tests check disabled segments, focus, label identity, and editor drafts.
Unit tests check inheritance, registry preservation, selection precedence, and shared metrics.

The `card` recipe now owns its zero padding.
Add `p-6` when applying the raw recipe to a padded surface.
The `CNCard` component keeps its existing padding behavior.
Keep reusable override presets in stored properties to preserve their cache identity.

Verify nested inheritance, explicit replacement, state precedence, and stable cache identity.
Verify label identity, editor drafts, focus, native activation, and disabled behavior.
Verify both themes, both layout directions, and large text.
Keep search debouncing, source formatting, preferences, and preview management inside the demo.
