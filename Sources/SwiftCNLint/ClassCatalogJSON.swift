import Foundation
@_spi(Tooling) import SwiftCN

/// The class vocabulary as JSON for editor tooling, such as the swiftcn language server.
/// Generated from the parser's tables by `swift run swiftcn-lint --catalog-json`.
public enum ClassCatalogJSON {
    public struct Entry: Codable, Equatable, Sendable {
        public var name: String
        public var category: String
        public var description: String
        /// `color` for theme color classes, so editors can show a color item, and `internal` for
        /// modifiers that components register, which are valid but not worth suggesting.
        public var kind: String?
    }

    public struct Pattern: Codable, Equatable, Sendable {
        public var label: String
        public var description: String
        /// A completion snippet, such as `p-${1:4}`.
        public var snippet: String
        /// Matches every class in the family, for validation.
        public var regex: String
    }

    public struct Catalog: Codable, Equatable, Sendable {
        public var version: Int
        public var variants: [Entry]
        public var classes: [Entry]
        public var patterns: [Pattern]
    }

    public static func catalog() -> Catalog {
        let catalog = TWClassCatalog.self
        var classes: [Entry] = []
        func add(_ name: String, _ category: String, _ description: String, kind: String? = nil) {
            classes.append(Entry(name: name, category: category, description: description, kind: kind))
        }

        let textStyles = ["xs": ".caption", "sm": ".subheadline", "base": ".body", "lg": ".title3",
                          "xl": ".title2", "2xl": ".title", "3xl": ".largeTitle"]
        for size in catalog.fontSizes {
            add("text-\(size)", "Typography", "Font \(textStyles[size] ?? size). Scales with Dynamic Type.")
        }
        for weight in catalog.weights { add("font-\(weight)", "Typography", "Font weight .\(weight == "normal" ? "regular" : weight).") }
        add("text-start", "Typography", "Leading multiline text alignment.")
        add("text-center", "Typography", "Centered multiline text alignment.")
        add("text-end", "Typography", "Trailing multiline text alignment.")
        add("line-clamp-none", "Typography", "Remove an inherited line limit.")

        let radii: [String: TWRadius] = ["none": .none, "sm": .sm, "md": .md, "lg": .lg, "xl": .xl, "full": .full]
        for radius in catalog.radii {
            let points = TWTheme.standard.radius(radii[radius] ?? .md)
            add("rounded-\(radius)", "Borders", radius == "full" ? "Fully rounded corners (capsule)." : "Corner radius \(Int(points)) pt.")
        }
        add("rounded", "Borders", "Corner radius \(Int(TWTheme.standard.radius(.md))) pt (md).")
        add("border", "Borders", "1 pt border in the theme border color.")
        for shadow in catalog.shadows { add("shadow-\(shadow)", "Effects", shadow == "none" ? "Remove the shadow." : "Theme shadow \(shadow).") }
        add("shadow", "Effects", "Theme shadow sm.")
        add("w-full", "Size", "Fill the available width.")

        let colorRoles = [("text-", "Foreground color"), ("bg-", "Background color"), ("border-", "Border color"),
                          ("tint-", "Native control tint"), ("glass-tint-", "Liquid Glass tint")]
        for color in catalog.colors {
            for (prefix, role) in colorRoles { add(prefix + color, "Color", "\(role): theme color \(color).", kind: "color") }
        }

        let surfaces = [
            "surface-floating": "Liquid Glass on iOS 26 and macOS 26, a material with a themed edge before, solid under Reduce Transparency.",
            "surface-solid": "A solid themed surface. bg-* sets its color.",
            "glass": "Liquid Glass with the same fallbacks. On a button, Apple's .glass style.",
            "glass-prominent": "Prominent Liquid Glass. On a button, Apple's .glassProminent style.",
            "glass-interactive": "Apple's touch and pointer feedback for glass. Installs no gesture.",
        ]
        for name in catalog.surfaces { add(name, "Surfaces", surfaces[name] ?? "") }

        let bezels = ["bezel-prominent": ".borderedProminent", "bezel-bordered": ".bordered",
                      "bezel-borderless": ".borderless", "bezel-link": ".link on macOS, .borderless on iOS"]
        for name in catalog.bezels { add(name, "Buttons", "Native button style \(bezels[name] ?? name). Apple draws the bezel.") }
        let sizes = ["control-mini": ".mini", "control-sm": ".small", "control-md": ".regular", "control-lg": ".large", "control-xl": ".extraLarge"]
        for name in catalog.controlSizes { add(name, "Buttons", ".controlSize(\(sizes[name] ?? name)).") }

        let presets = ["none": "Disable animation for styled values.", "linear": "Native .linear curve.",
                       "ease-in": "Native .easeIn curve.", "ease-out": "Native .easeOut curve.", "ease-in-out": "Native .easeInOut curve.",
                       "spring": "Native .spring with duration-*.", "smooth": "Native .smooth spring.",
                       "snappy": "Native .snappy spring.", "bouncy": "Native .bouncy spring."]
        for preset in catalog.animationPresets { add("animate-\(preset)", "Animation", presets[preset] ?? "Animation preset.") }

        let shared = ["shared-frame": "Match frame (default).", "shared-position": "Match position only.",
                      "shared-size": "Match size only.", "shared-source": "This endpoint is the source (default).",
                      "shared-follower": "This endpoint follows the source."]
        for name in catalog.sharedElements { add(name, "Shared elements", shared[name] ?? "") }
        add("group", "Shared elements", "Declare a group for group variants and shared elements.")

        for recipe in catalog.recipes {
            add(recipe, "Recipes", "swiftcn recipe used by components. Redefine it with TWGlobalRules(named:).")
        }
        let componentModifiers = catalog.componentRules.modifiers.keys.sorted()
        for name in componentModifiers {
            add(name, "Components", "Native modifier that swiftcn components register.", kind: "internal")
        }

        let variants = catalog.variants.map { variant -> Entry in
            let state = variant.replacingOccurrences(of: "group-", with: "")
            let description = variant.hasPrefix("group-")
                ? "Apply when the nearest group (or group/{name}) is \(state == "active" ? "pressed" : state)."
                : "Apply while the view is \(state == "active" ? "pressed" : state)."
            return Entry(name: variant, category: "Variants", description: description, kind: nil)
        }

        let number = #"\d+(\.\d+)?"#
        var patterns = [
            Pattern(label: "p-{n} px-{n} py-{n} pt-{n} pb-{n} ps-{n} pe-{n}", description: "Padding in theme units (4 pt each).",
                    snippet: "p-${1:4}", regex: "^(p|px|py|pt|pb|ps|pe|pl|pr)-\(number)$"),
            Pattern(label: "w-{n} h-{n} min-h-{n}", description: "Width, height, or minimum height in theme units (4 pt each).",
                    snippet: "w-${1:12}", regex: "^(w|h|min-h)-\(number)$"),
            Pattern(label: "opacity-{0…100}", description: "Opacity as a percentage.", snippet: "opacity-${1:80}",
                    regex: #"^opacity-(\d{1,2}(\.\d+)?|100)$"#),
            Pattern(label: "border-{n}", description: "Border width in points.", snippet: "border-${1:2}", regex: "^border-\(number)$"),
            Pattern(label: "line-clamp-{n}", description: "Native line limit.", snippet: "line-clamp-${1:2}", regex: #"^line-clamp-[1-9]\d*$"#),
            Pattern(label: "duration-{ms}", description: "Animation duration in milliseconds.", snippet: "duration-${1:200}",
                    regex: "^duration-\(number)$"),
            Pattern(label: "delay-{ms}", description: "Animation delay in milliseconds.", snippet: "delay-${1:100}", regex: "^delay-\(number)$"),
            Pattern(label: "group/{name}", description: "Declare a named group.", snippet: "group/${1:hero}", regex: #"^group/[A-Za-z0-9_.-]+$"#),
            Pattern(label: "shared-[{id}]", description: "Match a shared element within the nearest or a named group.",
                    snippet: "shared-[${1:cover}]", regex: #"^shared-\[[A-Za-z0-9_.-]+\](/[A-Za-z0-9_.-]+)?$"#),
        ]
        let arguments: [String: String] = [
            "w": "Width in points.", "h": "Height in points.", "size": "Width and height in points.",
            "min-w": "Minimum width in points.", "max-w": "Maximum width in points.", "min-h": "Minimum height in points.",
            "max-h": "Maximum height in points.", "p": "Padding in points.", "px": "Horizontal padding in points.",
            "py": "Vertical padding in points.", "pt": "Top padding in points.", "pb": "Bottom padding in points.",
            "ps": "Leading padding in points.", "pe": "Trailing padding in points.", "pl": "Leading padding in points.",
            "pr": "Trailing padding in points.", "rounded": "Corner radius in points.", "border": "Border width in points, or a color.",
            "text": "Font size in points, or a color.", "bg": "Background color: #hex or a theme color.",
            "tint": "Control tint: #hex or a theme color.", "glass-tint": "Liquid Glass tint: #hex or a theme color.",
            "opacity": "Opacity from 0 to 1.", "tracking": "Character tracking in points.", "line-spacing": "Gap between lines in points.",
            "line-clamp": "Line limit.", "offset": "x,y offset in points.", "scale": "Uniform or x,y scale.",
            "rotate": "Rotation in degrees (or rad).", "blur": "Blur radius in points.", "duration": "Duration (ms or s).",
            "delay": "Delay (ms or s).", "shared": "Shared element ID.", "animate": "An interpolated native Animation.",
        ]
        for entry in catalog.argumentExamples where entry.prefix != "shared" {
            let value = entry.example.flatMap { example in
                example.range(of: "-[").map { String(example[$0.upperBound...].dropLast()) }
            } ?? "\\\\(animation)"
            let escapedPrefix = NSRegularExpression.escapedPattern(for: entry.prefix)
            patterns.append(Pattern(label: "\(entry.prefix)-[…]", description: arguments[entry.prefix] ?? "Arbitrary value.",
                                    snippet: "\(entry.prefix)-[${1:\(value)}]", regex: "^\(escapedPrefix)-\\[.+\\]$"))
        }
        let internalPrefixes = componentModifiers.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        patterns.append(Pattern(label: "cn-…-[…]", description: "Native modifiers that swiftcn components register.",
                                snippet: "", regex: "^(\(internalPrefixes))-\\[.+\\]$"))
        return Catalog(version: 1, variants: variants, classes: classes.sorted { $0.name < $1.name }, patterns: patterns)
    }

    public static func encoded() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(catalog()), as: UTF8.self) + "\n"
    }
}
