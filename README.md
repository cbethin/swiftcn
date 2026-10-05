# swiftcn

String and typed utility styling with editable recipes for native SwiftUI.

![swiftcn catalog in light mode](docs/images/catalog-light.png)

```swift
import SwiftUI
import SwiftCN

Text("Workspace")
    .tw(.text(.lg), .weight(.semibold), .p(4), .bg(.surface), .rounded(.lg))

Button("Save", action: save)
    .buttonStyle(.tw(.primaryButton))
    .keyboardShortcut(.defaultAction)
```

swiftcn starts with a small styling layer for SwiftUI.
Compose string or typed utilities, share theme values, and edit named styles in ordinary Swift.
Keep native controls, layout, state, and interaction in your application.

Requires Swift 6, iOS 17 or later, or macOS 14 or later.
This repository contains the initial implementation. The API can change before a stable release.

## Install

Add this repository in Xcode with **File → Add Package Dependencies**.
Select the `main` branch and add the `SwiftCN` product.

For a Swift package, add:

```swift
dependencies: [
    .package(url: "https://github.com/cbethin/swiftcn.git", branch: "main")
]
```

Add the product to your target:

```swift
.product(name: "SwiftCN", package: "swiftcn")
```

You can also copy `Sources/SwiftCN` into your application or a local package that you own.
Copy all Swift files in that directory.
Keep the MIT license with copied source.
The library source has no external runtime dependencies or generated files.
The test target uses Point-Free SnapshotTesting.

## Utilities

```swift
Text("Project settings")
    .tw(
        .text(.xl),
        .weight(.semibold),
        .fg(.foreground),
        .px(6),
        .py(4),
        .bg(.surface),
        .border(.border),
        .rounded(.lg),
        .shadow(.sm)
    )
```

| Utility | Description |
| --- | --- |
| `.p`, `.px`, `.py`, `.pt`, `.pb`, `.ps`, `.pe` | Padding in theme units; `ps` and `pe` use leading and trailing edges |
| `.paddingPoints(12)` | Padding in explicit points |
| `.text(.lg)`, `.font(.headline)`, `.weight(.bold)` | Scalable font tokens, native fonts, and weights |
| `.fg(.foreground)`, `.bg(.surface)` | Semantic theme colors |
| `.fgColor(.blue)`, `.bgColor(.orange)` | Native color overrides |
| `.rounded(.lg)`, `.radius(12)` | Corners for the surface background and border |
| `.border(.border, width: 1)` | Semantic border color and width in points |
| `.borderColor(.blue, width: 2)` | Native border color |
| `.shadow(.sm)` | Shadow on the surface background |
| `.opacity(0.8)` | Opacity for the complete surface |
| `.w(200)`, `.h(44)`, `.minH(44)`, `.fullWidth` | Outer dimensions, minimum height, or available width |

The default spacing unit is four points.
`.p(4)` selects 16 points.
Typography tokens use scalable SwiftUI font roles.
Padding, radius, width, and height inputs must be finite and nonnegative.
Opacity inputs must lie between zero and one.

## Composition and overrides

```swift
extension TWStyle {
    static var projectCard: TWStyle {
        TWStyle(.card, .p(5), .rounded(.xl))
    }
}

VStack(alignment: .leading) {
    Text("Workspace")
    Text("Three active projects")
}
.tw(.projectCard, .p(8))
```

Within one `.tw(...)` call, later base utilities replace earlier values by property.
Padding resolves separately for each edge.
`.p(4), .px(6)` produces 16 points vertically and 24 points horizontally.
Utility order resolves properties; it does not reorder the rendering pipeline.

Separate `.tw(...)` calls create separate styled surfaces.
For example, `.tw(.p(2)).tw(.p(3))` adds both layers of padding.
Native modifiers retain their order around each surface.

## Theme

```swift
var theme = TWTheme(spacingUnit: 5)
theme.colors[.primary] = TWAdaptiveColor(light: .indigo, dark: .mint)
theme.colors[.onPrimary] = TWAdaptiveColor(light: .white, dark: .black)
theme.radii[.lg] = 16

ContentView()
    .twTheme(theme)
```

Semantic colors resolve through the current color scheme.
The theme inherits through the SwiftUI environment and supports local overrides.
Partial theme initializers preserve unspecified defaults.

Read theme values for native layouts:

```swift
@Environment(\.twTheme) private var theme

VStack(spacing: theme.space(4)) {
    Text("First")
    Text("Second")
}
```

Add custom semantic colors through ordinary Swift extensions:

```swift
extension TWColor {
    static let brand = TWColor("brand")
}

let theme = TWTheme(colors: [
    .brand: TWAdaptiveColor(light: .purple, dark: .pink)
])

Text("Brand").tw(.fg(.brand)).twTheme(theme)
```

Register custom colors in the theme before using them.
Unregistered colors fall back to SwiftUI's semantic primary foreground.

## Native buttons and state variants

```swift
Button("Save", action: save)
    .buttonStyle(.tw(.primaryButton))
    .disabled(isSaving)

Button("Delete", role: .destructive, action: delete)
    .buttonStyle(.tw(.destructiveButton))
```

Built-in recipes include `card`, `primaryButton`, `secondaryButton`, `outlineButton`, and `destructiveButton`.
The button adapter uses `ButtonStyle.Configuration.isPressed`.
SwiftUI retains the button's action, semantic role, and activation behavior.
Appearance variants do not set semantic roles.
Button recipes use a minimum height of 44 points on iOS and 32 points on macOS.
Large text can increase that height.

```swift
TWStyle(
    .opacity(1),
    .hover(.bg(.accent)),
    .pressed(.opacity(0.8)),
    .disabled(.opacity(0.45))
)
```

Active patches apply after base utilities.
State precedence is hover, focus, pressed, then disabled.
For equal precedence, more specific nested conditions win before declaration order.
Conditions affect appearance only.
Use native `.disabled(...)` to disable a control.

Hover follows native pointer events.
General view styling does not recognize presses or assign focus.
Supply explicit focus state when a control owns it:

```swift
@FocusState private var emailFocused: Bool

TextField("Email", text: $email)
    .focused($emailFocused)
    .tw(.border(.border), .rounded(.md),
        .focus(.border(.primary, width: 2)),
        state: TWState(isFocused: emailFocused))
```

## Rendering contract

The renderer uses a stable content structure when state patches change values.
It applies typography and foreground, then padding, dimensions, background, border, and opacity.
The background owns the surface shadow.
Unspecified fonts and foreground colors inherit from the surrounding view.
Corners affect the background and border without clipping content.
Decorative borders do not intercept input.

Use native SwiftUI modifiers for gradients, materials, clipping, animation, and custom effects.
Keep toggle, picker, and menu presentation in their native styling APIs.
Gesture helpers and responsive variants remain outside this initial release.

## Catalog and checks

Run the interactive macOS catalog:

```sh
swift run --package-path Examples/Catalog SwiftCNCatalog
```

Render light and dark catalog images:

```sh
swift run --package-path Examples/Catalog SwiftCNCatalog --render artifacts
```

Run checks:

```sh
swift test
swift build -c release
bash Scripts/check-source-copy.sh
bash Scripts/check-ios.sh
```

Tests cover property resolution, state precedence, color inheritance, adaptive themes, native rendering, and child state identity.
The iOS script compiles the library against the simulator SDK.
Simulator compilation does not establish physical device behavior.
Keyboard activation and VoiceOver still require checks in an application host.
See [the architecture](docs/architecture.md) for the boundaries and next steps.
See [the dark catalog](docs/images/catalog-dark.png) for the alternate appearance.

## License

MIT. See [LICENSE](LICENSE).

## String classes and global rules

Compose classes with ordinary Swift strings:

```swift
let emphasis = isImportant ? "bg-primary text-primary-foreground" : "bg-accent text-accent-foreground"

Text("Status").tw("px-4 py-2 rounded-md \(emphasis)")
Button("Save") { save() }
    .buttonStyle(.tw("button-primary px-6 hover:opacity-90 disabled:opacity-40"))
```

Strings and typed utilities use the same resolver. Later classes replace earlier values for the same property.
State variants keep their existing priority: hover, focus, press, then disabled.
Use `active:` or `pressed:` for the pressed appearance. Combine variants with colons, such as `disabled:hover:opacity-20`.

Pass focus through `TWState`. SwiftUI owns button activation and gesture recognition.

Supported classes include:

| Kind | Classes |
| --- | --- |
| Spacing | `p-4`, `px-2.5`, `py-2`, `pt-1`, `pb-1`, `ps-2`, `pe-2` |
| Size | `w-12`, `h-10`, `min-h-11`, `w-full` |
| Typography | `text-xs` through `text-3xl`, `font-medium`, `font-semibold`, `font-bold` |
| Colors | `bg-primary`, `text-foreground`, `text-muted-foreground`, `text-primary-foreground` |
| Decoration | `rounded-md`, `rounded-full`, `border`, `border-2`, `border-primary`, `shadow-sm`, `opacity-80` |
| Recipes | `card`, `button-primary`, `button-secondary`, `button-outline`, `button-destructive` |

Numeric sizes use the theme spacing scale, as Tailwind does. Typed `.w()`, `.h()`, and `.minH()` continue to accept points.
Border widths use points. `pl-` and `pr-` alias logical leading and trailing spacing.

Custom color tokens also work in strings. Use adaptive theme colors for light and dark appearances.
This grammar covers native decoration. It does not implement CSS layout, responsive breakpoints, or arbitrary CSS values.

Set rules at the app root:

```swift
let brand = TWColor("brand")
let theme = TWTheme(colors: [
    brand: TWAdaptiveColor(light: .indigo, dark: .mint)
])
let rules = TWGlobalRules(
    view: "text-sm",
    button: "min-h-12",
    named: [
        "brand-button": TWStyle(.primaryButton, .bg(brand), .rounded(.full)),
        "compact-card": "card p-3"
    ]
)

ContentView()
    .twTheme(theme)
    .twRules(rules)

// Inside ContentView:
Button("Continue") { continueAction() }
    .buttonStyle(.tw("brand-button px-8"))
Text("Details").tw("compact-card")
```

Global view defaults affect each explicit `.tw` surface and each `TWButtonStyle` label.
Button defaults affect only `TWButtonStyle` labels. Local styles override these defaults within the same state.
Unstyled descendants receive no extra padding, backgrounds, or gesture recognizers.

Replace a built-in recipe for both typed and string callers:

```swift
var rules = TWGlobalRules()
let base = TWStyle.defaultStyle(for: "button-primary")!
rules.named["button-primary"] = TWStyle(base, .rounded(.full), .minH(48))
```

Use `defaultStyle(for:)` when extending the same recipe. Referencing `.primaryButton` inside its own replacement creates a cycle.
Change selected inherited rules in a subtree:

```swift
SettingsView().twRules { rules in
    rules.named["card"] = .classes("p-3 rounded-sm border bg-surface")
}
```

The closure preserves other inherited rules. Passing a `TWGlobalRules` value replaces the configuration for that subtree.
Rules use SwiftUI's environment and stay isolated between windows and previews.

Validate generated strings with `try TWStyle.parse(classes, rules: rules, theme: theme)`.
Unknown classes, unknown variants, and recursive named classes throw `TWClassError`.
The convenient view API logs invalid styles through the system logger and leaves that surface undecorated.
Use strict parsing in tests to catch spelling errors. `.classes()` resolves strings against the current environment during rendering.

## Visual regression tests

The visual suite compares 42 images with exact pixels: 34 macOS views and eight iOS simulator screenshots.
It covers themes, widths, text-size environments, state appearances, native controls, global rules, and right-to-left layout.
The CI job fails on missing or changed references and uploads difference images.
See [the visual testing guide](docs/visual-testing.md) for local commands and baseline updates.
