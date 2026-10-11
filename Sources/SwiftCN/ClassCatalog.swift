import SwiftUI

/// The class vocabulary that the parser accepts with the standard theme and default rules.
/// Build-time checks use it for suggestions, and the generated class reference lists it.
/// Tests parse every entry, so the catalog cannot drift from the parser.
@_spi(Tooling) public enum TWClassCatalog {
    /// A family of classes that shares one pattern, such as `p-{n}`.
    public struct Family: Sendable {
        public let pattern: String
        public let summary: String
        public let examples: [String]
    }

    /// Rules with the native modifiers that swiftcn components register when they render.
    /// Recipes such as `avatar` and `progress` expand to those modifiers.
    public static var componentRules: TWGlobalRules {
        TWGlobalRules(modifiers: [
            "cn-tint": CNUtilities.tint,
            "cn-aspect": CNUtilities.aspect,
            "cn-mono": CNUtilities.monospaced,
            "cn-avatar-crop": CNUtilities.avatarCrop,
            "cn-avatar-image": CNUtilities.avatarImage,
            "cn-shimmer": CNLoadingUtilities.shimmer,
            "cn-spin": CNLoadingUtilities.spin,
        ])
    }

    public static let variants = ["hover", "focus", "active", "pressed", "disabled",
                                  "group-hover", "group-focus", "group-active", "group-pressed", "group-disabled"]

    /// Theme colors and their aliases, as class suffixes.
    public static var colors: [String] {
        (TWTheme.standard.colors.keys.map(\.rawValue) + TWClassParser.aliases.keys).sorted()
    }

    public static var fontSizes: [String] { TWText.allCases.compactMap { size in TWClassParser.fonts.first { $0.value == size }?.key } }
    public static var weights: [String] { TWClassParser.weights.keys.sorted() }
    public static var radii: [String] { TWRadius.allCases.compactMap { radius in TWClassParser.radii.first { $0.value == radius }?.key } }
    public static var shadows: [String] { TWShadow.allCases.compactMap { shadow in TWClassParser.shadows.first { $0.value == shadow }?.key } }
    public static var animationPresets: [String] { TWAnimation.defaults.keys.sorted() }
    public static var recipes: [String] { TWStyle.defaultClasses.keys.filter { !$0.hasPrefix("cn-") }.sorted() }

    public static let surfaces = ["surface-floating", "surface-solid", "glass", "glass-prominent", "glass-interactive"]
    public static let bezels = ["bezel-prominent", "bezel-bordered", "bezel-borderless", "bezel-link"]
    public static let controlSizes = ["control-mini", "control-sm", "control-md", "control-lg", "control-xl"]
    public static let sharedElements = ["shared-frame", "shared-position", "shared-size", "shared-source", "shared-follower"]
    public static let standalone = ["group", "w-full", "h-full", "border", "rounded", "shadow",
                                    "text-center", "text-start", "text-end", "line-clamp-none"]

    /// One working example for each bracket prefix. `animate-[…]` only accepts interpolated native values.
    public static let argumentExamples: [(prefix: String, example: String?)] = [
        ("w", "w-[240]"), ("h", "h-[80]"), ("size", "size-[44]"),
        ("min-w", "min-w-[80]"), ("max-w", "max-w-[300]"), ("min-h", "min-h-[44]"), ("max-h", "max-h-[200]"),
        ("p", "p-[13]"), ("px", "px-[12]"), ("py", "py-[8]"), ("pt", "pt-[4]"), ("pb", "pb-[4]"),
        ("ps", "ps-[4]"), ("pe", "pe-[4]"), ("pl", "pl-[4]"), ("pr", "pr-[4]"),
        ("rounded", "rounded-[14]"), ("border", "border-[1.5]"),
        ("text", "text-[18]"), ("bg", "bg-[#6366f1]"), ("tint", "tint-[#ff7a59]"), ("glass-tint", "glass-tint-[#ff7a59]"),
        ("opacity", "opacity-[0.8]"), ("tracking", "tracking-[0.5]"), ("line-spacing", "line-spacing-[4]"),
        ("line-clamp", "line-clamp-[2]"), ("offset", "offset-[12,-4]"), ("scale", "scale-[1.05]"),
        ("rotate", "rotate-[3deg]"), ("blur", "blur-[2]"), ("duration", "duration-[400ms]"), ("delay", "delay-[75ms]"),
        ("shared", "shared-[cover]"), ("animate", nil),
    ]

    public static var argumentPrefixes: [String] { argumentExamples.map(\.prefix) }

    /// Every concrete class name, without numeric scale families.
    public static var exactClasses: [String] {
        var names = surfaces + bezels + controlSizes + sharedElements + standalone + recipes
        names += fontSizes.map { "text-\($0)" } + weights.map { "font-\($0)" }
        names += radii.map { "rounded-\($0)" } + shadows.map { "shadow-\($0)" }
        names += animationPresets.map { "animate-\($0)" }
        for color in colors {
            names += ["text-", "bg-", "border-", "tint-", "glass-tint-"].map { $0 + color }
        }
        return names
    }

    public static let families: [Family] = [
        Family(pattern: "p-{n} px-{n} py-{n} pt-{n} pb-{n} ps-{n} pe-{n}",
               summary: "Padding in theme units (4 points each by default). ps and pe use leading and trailing edges; pl and pr are aliases.",
               examples: ["p-4", "px-6", "py-2.5"]),
        Family(pattern: "w-{n} h-{n} min-h-{n}", summary: "Width, height, and minimum height in theme units.",
               examples: ["w-12", "h-10", "min-h-11"]),
        Family(pattern: "border-{n}", summary: "Border width in points.", examples: ["border-2"]),
        Family(pattern: "opacity-{0…100}", summary: "Opacity as a percentage.", examples: ["opacity-80"]),
        Family(pattern: "line-clamp-{n}", summary: "Native line limit.", examples: ["line-clamp-2"]),
        Family(pattern: "duration-{ms} delay-{ms}", summary: "Animation timing in milliseconds.",
               examples: ["duration-200", "delay-100"]),
        Family(pattern: "group/{name}", summary: "Declare a named group for group variants and shared elements.",
               examples: ["group/hero"]),
        Family(pattern: "shared-[{id}] shared-[{id}]/{group}", summary: "Match a shared element within the nearest or a named group.",
               examples: ["shared-[cover]", "shared-[cover]/hero"]),
    ]

    private static let scaleSamples = ["0", "0.5", "1", "1.5", "2", "2.5", "3", "4", "5", "6", "8", "10", "12", "16", "20", "24"]

    /// Concrete names that suggestions compare against, including common scale values.
    public static var suggestionCandidates: [String] {
        var names = exactClasses
        for prefix in ["p", "px", "py", "pt", "pb", "ps", "pe", "w", "h", "min-h"] {
            names += scaleSamples.map { "\(prefix)-\($0)" }
        }
        names += stride(from: 0, through: 100, by: 5).map { "opacity-\($0)" }
        names += ["0", "1", "2", "4"].map { "border-\($0)" }
        names += ["75", "100", "150", "200", "300", "500", "700", "1000"].flatMap { ["duration-\($0)", "delay-\($0)"] }
        names += (1...6).map { "line-clamp-\($0)" }
        return names
    }

    /// The closest known class to a misspelled one, keeping any variants, or nil when nothing is close.
    public static func suggestion(for token: String, extraNames: [String] = []) -> String? {
        var parts = token.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let name = parts.popLast(), !name.isEmpty else { return nil }
        guard let match = closest(to: name, in: suggestionCandidates + extraNames) else { return nil }
        return (parts + [match]).joined(separator: ":")
    }

    /// The closest known variant to a misspelled one.
    public static func variantSuggestion(for variant: String) -> String? {
        let base = variant.split(separator: "/", maxSplits: 1).first.map(String.init) ?? variant
        guard let match = closest(to: base, in: variants) else { return nil }
        return variant.contains("/") ? match + variant.drop { $0 != "/" } : match
    }

    public static func closest(to name: String, in candidates: [String]) -> String? {
        let limit = max(1, min(3, name.count / 3))
        var best: (name: String, distance: Int)?
        for candidate in Set(candidates) where candidate != name {
            let distance = editDistance(name, candidate, limit: limit)
            guard distance <= limit else { continue }
            if best == nil || distance < best!.distance || (distance == best!.distance && candidate < best!.name) {
                best = (candidate, distance)
            }
        }
        return best?.name
    }

    /// Levenshtein distance that stops early once every path exceeds the limit.
    static func editDistance(_ a: String, _ b: String, limit: Int) -> Int {
        let a = Array(a), b = Array(b)
        guard abs(a.count - b.count) <= limit else { return limit + 1 }
        var previous = Array(0...b.count)
        for i in 1...max(a.count, 1) where !a.isEmpty {
            var current = [i] + Array(repeating: 0, count: b.count)
            var rowMinimum = current[0]
            for j in 1...max(b.count, 1) where !b.isEmpty {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > limit { return limit + 1 }
            previous = current
        }
        return a.isEmpty ? b.count : previous[b.count]
    }
}
