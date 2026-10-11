import { docsLlms } from '@/lib/source';

export const revalidate = false;

const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

// Notes that keep coding agents inside swiftcn's actual vocabulary.
const preamble = `# swiftcn

> Typed utility styling and editable component recipes for native SwiftUI. Tailwind-style classes such as \`.tw("p-4 bg-surface rounded-lg")\` resolve to ordinary SwiftUI modifiers, button classes select Apple's native button styles, and 64 components are source you can copy and edit. Swift 6, iOS 17+, macOS 14+, no runtime dependencies.

Notes for writing swiftcn code:

- Only the classes in the [class reference](${basePath}/classes.md) are valid. swiftcn is not Tailwind's full set: there are no responsive breakpoints, flex or grid utilities, percentages, \`rem\`, \`calc\`, or CSS variables. Use native SwiftUI stacks for layout.
- One invalid class leaves the whole surface unstyled at run time. Run \`swift package swiftcn-lint\` (or \`swift run swiftcn-lint Sources --format json\`) after editing class strings; each problem includes a suggested replacement.
- Bracket values use native units: \`w-[240]\` is 240 points, \`duration-[400]\` is 400 milliseconds, \`rotate-[3]\` is 3 degrees. Interpolate Swift values inside brackets: \`rotate-[\\(angle)]\`.
- Typed utilities have the same vocabulary with compiler checks: \`.tw(.p(4), .bg(.surface), .rounded(.lg))\`.
- Use \`.buttonStyle(.tw("button-primary"))\` for buttons; Apple draws the bezel.
- Keep state, focus, gestures, and navigation in SwiftUI. Classes only describe appearance and animation.

`;

export async function GET() {
  const index = (await docsLlms.index()).replace(/^# Docs/, '## Docs');
  return new Response(preamble + index);
}
