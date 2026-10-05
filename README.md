# swiftcn

String and typed utility styling with editable recipes for native SwiftUI.

![swiftcn catalog in light mode](docs/images/catalog-light.png)

```swift
import SwiftUI
import SwiftCN

Text("Workspace")
    .tw("text-lg font-semibold p-4 bg-surface rounded-lg")

Button("Save", action: save)
    .buttonStyle(.tw("button-primary"))
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

## Native animation classes

Use animation classes to animate changes to the modifiers that `.tw` owns:

```swift
Button("Save", action: save)
    .buttonStyle(.tw("button-primary active:opacity-80 animate-spring duration-150"))

Text("Details")
    .tw("\(expanded ? "p-6 rounded-xl" : "p-3 rounded-md") bg-surface animate-ease-out duration-200")
```

SwiftUI owns the state and interpolates the native modifier values.
Button press and release, hover, explicit focus, and computed strings use the same animation rules.
You do not need an extra `.animation(..., value:)` call for these styled values.
The modifier structure stays stable during these changes.

| Class | Native animation |
| --- | --- |
| `animate-linear` | `.linear(duration:)` |
| `animate-ease-in`, `animate-ease-out`, `animate-ease-in-out` | Native timing curves |
| `animate-spring` | `.spring(duration:)` |
| `animate-smooth`, `animate-snappy`, `animate-bouncy` | Native spring presets |
| `animate-none` | Disable animation for the styled modifiers |
| `duration-200`, `delay-100` | Duration and delay in milliseconds |

The default duration is 300 milliseconds. The default delay is zero.
Timing utilities accept finite, nonnegative decimal values.
Later utilities override the same property. State variants use the normal precedence rules.

The destination state selects the animation, including during release or focus loss.
Keep a base animation class when both entry and exit need animation.

Without an animation class, `.tw` preserves the caller's transaction.
Duration and delay alone do not enable animation.
Explicit animation classes respect Reduce Motion and `Transaction.disablesAnimations`.
The scoped transaction affects the styled modifiers and preserves the content's existing transaction.
Native modifiers outside `.tw` keep their own animation settings.

Animation classes configure value changes; they do not start a repeating animation on appearance.
View insertion and removal continue to use native `.transition` and application transactions.

Set custom presets through global rules:

```swift
let rules = TWGlobalRules(
    named: ["motion-card": "card animate-settle duration-250"],
    animations: [
        "settle": TWAnimation { duration in
            .spring(duration: duration, bounce: 0.15)
        },
        "press": TWAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8))
    ]
)

ContentView().twRules(rules)
// Inside ContentView:
Text("Details").tw("motion-card")
Button("Save", action: save).buttonStyle(.tw("button-primary animate-press"))
```

Preset factories receive the resolved duration in seconds.
A fixed native preset keeps its own duration; `duration-*` does not retime it.
Both forms accept `delay-*`. Partial preset dictionaries preserve built-in presets.
Subtree updates can replace individual presets through `rules.animations`.
String presets resolve against the current rules during rendering.

Typed utilities use the same rules:

```swift
Text("Details").tw(.p(4), .animation(.spring), .duration(0.2), .delay(0.05))
```

Typed duration and delay utilities accept seconds.

## Shared elements

Pair views with `.twShared` and a native `@Namespace`.
Use `.twAnimation` on their common container to animate layout and content when a state value changes.

```swift
struct HeroCard: View {
    @Namespace private var hero
    @State private var expanded = false

    private var cover: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.indigo)
            .twShared("cover", in: hero)
    }

    var body: some View {
        VStack {
            ZStack {
                if expanded {
                    cover.frame(width: 320, height: 200)
                } else {
                    cover.frame(width: 80, height: 80)
                }
            }
            Button("Toggle") { expanded.toggle() }
                .buttonStyle(.tw("button-primary"))
        }
        .twAnimation("animate-smooth duration-400", value: expanded)
    }
}
```

`.twShared` wraps native [matched geometry](https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect(id:in:properties:anchor:issource:)).
It accepts any `Hashable` ID and retains the native `properties`, `anchor`, and `isSource` options.
Apply it before different fixed frames to interpolate their sizes.
Apply it after `.tw` when the pair represents the entire styled surface.
Use `properties: .position` for a title that keeps its destination size.

Use the same namespace and ID at both endpoints within one view hierarchy.
Keep one source per pair. If both endpoints stay visible, mark the follower with `isSource: false`.
The helper synchronizes geometry; use native transitions for content appearance and removal.
It does not connect independent windows or presentation hosts.
Reduce Motion suppresses the shared geometry animation while retaining its final geometry.

`.twAnimation` uses the same presets, timing classes, named rules, and custom animations as `.tw`.
It also accepts typed utilities: `.twAnimation(.animation(.smooth), .duration(0.4), value: expanded)`.
It reads animation defaults from `rules.view`. Non-animation utilities do not decorate the container.

Without a preset, it preserves the caller's transaction.
Explicit presets respect Reduce Motion and `Transaction.disablesAnimations`.
The watched value controls the transaction for the subtree, including other changes in the same update.
Use `.tw` for animation limited to styled values; use `.twAnimation` for layout, insertion, removal, and shared elements.

## Rendering contract

The renderer uses a stable content structure when state patches change values.
It applies typography and foreground, then padding, dimensions, background, border, and opacity.
The background owns the surface shadow.
Unspecified fonts and foreground colors inherit from the surrounding view.
Corners affect the background and border without clipping content.
Decorative borders do not intercept input.

Use native SwiftUI modifiers for gradients, materials, clipping, transitions, and custom effects.
Keep toggle, picker, and menu presentation in their native styling APIs.
Gesture helpers and responsive variants remain outside this initial release.

## Catalog and checks

Run the interactive macOS catalog:

```sh
bash Scripts/run-demo.sh
```

The script builds and opens `artifacts/SwiftCN Demo.app`.
The app includes components, motion, shared elements, and global rules playgrounds.
Change animation presets and timing while toggling the styled surface.
Edit shared classes, palettes, spacing, and subtree overrides in the global rules playground.
The appearance picker selects system, light, or dark mode.

The demo adds gentle entrances, hover and press feedback, animated counters, and native symbol effects.
These effects respect Reduce Motion. Static image exports disable the demo effects.

Run the executable directly with `swift run --package-path Examples/Catalog SwiftCNCatalog`.

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
| Motion | `animate-spring`, `animate-ease-out`, `animate-none`, `duration-200`, `delay-100` |

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

Recipes contain their own defaults and override the view and button defaults.
Replace a named recipe to change its defaults across the application.

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
