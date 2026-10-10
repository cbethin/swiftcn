# Architecture

swiftcn supplies appearance values for native SwiftUI views through typed utilities and string classes.
Its initial scope includes a theme, utilities, a resolver, a renderer, and a native button adapter.

## Ownership

Keep the styling source readable and independent from external dependencies.
Allow application sources and local Swift packages as destinations.
Keep recipes editable through ordinary Swift extensions.
Build source distribution from these boundaries when the catalog grows.

## Utility values

`TWStyle` stores an ordered list of property rules.
Utilities and named recipes produce the same value type.
Each conditional rule stores its active state requirements.
Nested conditions require all their states to match.

Expand string classes through the same utilities before property resolution.
Resolve named classes through environment rules at render time.
Reject unknown classes, unknown variants, and recursive definitions during strict parsing.

## Global rules

Store view defaults, button defaults, and named classes in `TWGlobalRules`.
Pass rules through the SwiftUI environment.
Apply defaults only to explicit styled surfaces.
Apply local utilities after global defaults within each state.
Use named recipe replacements to change built-in appearances across the application.
Keep subtree changes separate from sibling views.

## Resolution

Resolve matching base rules before active state rules.
Use state precedence in this order: hover, focus, pressed, disabled.
For equal precedence, apply general rules before more specific rules.
For equal specificity, apply rules in declaration order.
Store directional padding independently.
Resolve semantic tokens through the theme at render time.

## Rendering

Keep the content structure stable during value changes.
Use native modifiers for padding, dimensions, typography, background, and borders.
Keep rounded backgrounds separate from clipping.
Keep decorative overlays outside hit testing and accessibility.
Keep unspecified inherited appearance values intact.

## Native controls

Use `ButtonStyle` to supply pressed state without installing a recognizer.
Use the environment for enabled state.
Keep focus ownership explicit at the control.
Use native appearance APIs for controls without a suitable adapter.
Do not infer custom control semantics from appearance.

## Surfaces

Separate the theme from the appearance policy.
Resolve each surface role to one fill: glass, a material, or a solid color.
Choose the fill from the role, the policy, system support, and Reduce Transparency.
Keep native glass under accessibility settings; replace custom materials with solid fills.
Keep availability checks in the library.
Select the view structure from the surface role only. Change values for policy, system, and accessibility changes.
Choose native button style types without accessibility inputs.
Keep grouping and morph identity explicit through native containers and identifiers.
Do not install gestures from appearance classes.

## Animation

Store native animation presets, duration, and delay as independent style properties.
Resolve string presets through `TWGlobalRules.animations` at render time.
Allow fixed native animations and factories that receive the selected duration.
Keep global preset overrides inside the SwiftUI environment.

Apply the selected animation through a scoped native transaction around the appearance modifiers.
Preserve the content transaction across this scope.
Keep the modifier structure stable when the animation changes.
Let SwiftUI interpolate supported modifier values during state changes.
Use the destination state's animation settings.

Preserve the caller transaction when the style has no animation preset.
Respect Reduce Motion and transactions that disable animations.
Keep view insertion, removal, and repeating animation triggers in the application.

## Validation

Check property resolution and variant conflicts through unit tests.
Check appearance and inheritance through rendered native views.
Check child state identity through a hosted SwiftUI view.
Compile the library for an iOS simulator.
Copy the library sources into a clean package to check dependency boundaries.

Compare native hosted views against committed visual baselines.
Capture iOS simulator screenshots for native controls and Dynamic Type.
Cover both themes, two widths, text-size environments, control states, and directional layout.
Use exact pixel comparison on the selected continuous integration toolchain.
Keep local baselines separate from the continuous integration baselines.

Upload reference images, actual images, and differences after failures.
Record candidate baselines through a separate workflow.
Review candidate images before committing changes to the baselines.

## Next steps

1. Verify keyboard, VoiceOver, and touch behavior in application hosts.

2. Compare repeated recipes before adding more control adapters.

3. Add source installation metadata and a baseline for update comparisons.

4. Add gesture helpers through a separate interaction layer.

5. Evaluate container width variants after the styling interface stabilizes.
