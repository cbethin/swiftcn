# Architecture

swiftcn supplies typed appearance values for native SwiftUI views.
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

## Validation

Check property resolution and variant conflicts through unit tests.
Check appearance and inheritance through rendered native views.
Check child state identity through a hosted SwiftUI view.
Compile the library for an iOS simulator.
Copy the library sources into a clean package to check dependency boundaries.

## Next steps

1. Verify keyboard, VoiceOver, and touch behavior in application hosts.

2. Compare repeated recipes before adding more control adapters.

3. Add source installation metadata and a baseline for update comparisons.

4. Add gesture helpers through a separate interaction layer.

5. Evaluate container width variants after the styling interface stabilizes.
