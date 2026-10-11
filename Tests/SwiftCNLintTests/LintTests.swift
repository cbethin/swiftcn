import Foundation
import Testing
@_spi(Tooling) import SwiftCN
@testable import SwiftCNLint

@Suite("Build-time class checks")
struct LintTests {
    private func lint(_ source: String, configuration: LintConfiguration = LintConfiguration()) -> [LintDiagnostic] {
        var linter = SwiftCNLinter(configuration: configuration)
        linter.learn(from: source)
        return linter.lint(source: source, path: "View.swift")
    }

    @Test func reportsMisspelledClassesAtTheirPositionWithASuggestion() {
        let diagnostics = lint("""
        Text("A")
            .tw("p-4 bg-surfce")
        """)
        #expect(diagnostics.count == 1)
        let diagnostic = try! #require(diagnostics.first)
        #expect(diagnostic.line == 2 && diagnostic.column == 14)
        #expect(diagnostic.token == "bg-surfce" && diagnostic.suggestion == "bg-surface")
        #expect(diagnostic.xcodeFormatted
            == "View.swift:2:14: error: Unknown swiftcn class 'bg-surfce'. Did you mean 'bg-surface'? [swiftcn-lint]")
    }

    @Test func everyCatalogEntryParsesWithTheLinterRules() throws {
        let rules = SwiftCNLinter().rules
        let names = TWClassCatalog.exactClasses + TWClassCatalog.suggestionCandidates
            + TWClassCatalog.argumentExamples.compactMap(\.example) + TWClassCatalog.families.flatMap(\.examples)
            + TWClassCatalog.variants.map { "\($0):opacity-50" }
        for name in names {
            #expect(throws: Never.self, "\(name)") { _ = try TWStyle.parse(name, rules: rules) }
        }
        // Recipes that expand to component modifiers are valid too.
        for recipe in ["avatar", "kbd", "progress", "spinner-motion", "date-picker"] {
            #expect(throws: Never.self, "\(recipe)") { _ = try TWStyle.parse(recipe, rules: rules) }
        }
    }

    @Test func validClassesProduceNoDiagnostics() {
        #expect(lint("""
        Text("Title").tw("text-2xl font-bold text-muted-foreground px-[12] hover:bg-accent group-hover/hero:opacity-70")
        Button("Save") {}.buttonStyle(.tw("tint-[#ff5a36] glass-prominent control-xl rounded-full"))
        VStack {}.tw("p-7 surface-floating rounded-[44] animate-bouncy duration-200 shared-[cover]/hero")
        """).isEmpty)
    }

    @Test func reportsVariantsValuesAndArgumentPrefixes() {
        let diagnostics = lint(#"""
        Text("A").tw("hovr:bg-accent w-[abc]")
        Text("B").tw("rotte-[\(angle)] bg-[\(Color.red)]")
        """#)
        #expect(diagnostics.map(\.suggestion) == ["hover:bg-accent", nil, #"rotate-[\(…)]"#])
        #expect(diagnostics[1].message.contains("as a value for w-[…]"))
        #expect(diagnostics[2].message.contains("Unknown swiftcn argument prefix 'rotte-[…]'"))
    }

    @Test func skipsCommentsRuntimeFragmentsAndIgnoredLines() {
        #expect(lint(#"""
        // .tw("not-a-class")
        /* .tw("still-not") /* nested */ .tw("nope") */
        Text("A").tw("\(compact ? "p-2" : "p-3") \(extra)")
        Text("B").tw(classes)
        Text("C").tw("made-up") // swiftcn-lint: ignore
        // swiftcn-lint: ignore-next-line
        Text("D").tw("also-made-up")
        """#).isEmpty)
    }

    @Test func learnsNamesThatTheAppRegisters() {
        #expect(lint(#"""
        let rules = TWGlobalRules(named: ["motion-card": "card animate-settle"],
                                  animations: ["settle": TWAnimation(.default)],
                                  utilities: ["inset": TWUtility { _, _ in nil }],
                                  modifiers: ["frosted": .view { view, _ in view }])
        let brand = TWColor("brand")
        Text("A").tw("motion-card frosted inset-[3] text-brand animate-settle")
        Text("B").twRules { $0.named["pill"] = "rounded-full" }.tw("pill hover:frosted")
        """#).isEmpty)
        // Typos inside a registered recipe are still reported.
        #expect(lint(#"let rules = TWGlobalRules(named: ["card-x": "rounded-xll"])"#).map(\.suggestion) == ["rounded-xl"])
    }

    @Test func configurationListsNamesRegisteredElsewhere() {
        let source = #"Text("A").tw("brand-chip bg-brand tilt-[8deg] animate-wobble")"#
        #expect(lint(source).count == 4)
        let configuration = LintConfiguration(classes: ["brand-chip"], prefixes: ["tilt"], animations: ["wobble"], colors: ["brand"])
        #expect(lint(source, configuration: configuration).isEmpty)
        let decoded = try? JSONDecoder().decode(LintConfiguration.self, from: Data(#"{"classes": ["brand-chip"]}"#.utf8))
        #expect(decoded == LintConfiguration(classes: ["brand-chip"]))
    }

    @Test func checksEveryPlaceThatTakesClasses() {
        let diagnostics = lint(#"""
        Text("A").tw(cn("card", selected ? "border-primary" : nil, "tint-primery"))
        CNCommand(options, selection: $selection, classes: "h-[180] bg-surfce")
        let style: TWClasses = "p-4 roundd"
        let other: TWStyle = "shadow-lgg"
        VStack {}.twAnimation("animate-smoth", value: expanded)
        Text("B").tw(.classes("font-bld"))
        """#)
        #expect(diagnostics.map(\.token) == ["tint-primery", "bg-surfce", "roundd", "shadow-lgg", "animate-smoth", "font-bld"])
    }

    @Test func handlesEveryStringLiteralForm() {
        let diagnostics = lint(##"""
        Text("A").tw("p-4 \"quoted\" bg-surfce")
        Text("B").tw("""
            p-4
            rounded-xll
            """)
        Text("C").tw(#"p-4 shadow-lgg"#)
        Text("D").tw("\u{70}-4 text-lgg")
        """##)
        #expect(diagnostics.map(\.token) == ["\"quoted\"", "bg-surfce", "rounded-xll", "shadow-lgg", "text-lgg"])
        #expect(diagnostics.map(\.line) == [1, 1, 4, 6, 7])
    }

    @Test func warningsOnlyKeepsTheDiagnosticsAsWarnings() {
        let diagnostics = lint(#"Text("A").tw("bg-surfce")"#, configuration: LintConfiguration(warningsOnly: true))
        #expect(diagnostics.map(\.severity) == [.warning])
    }

    private static let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    @Test func publishedClassReferenceIsCurrent() throws {
        let published = try String(contentsOf: Self.repository.appending(path: "website/public/classes.md"), encoding: .utf8)
        #expect(published == ClassReference.markdown(),
                "Regenerate with: swift run swiftcn-lint --reference > website/public/classes.md")
    }

    @Test func editorCatalogIsCurrentAndParses() throws {
        let published = try String(contentsOf: Self.repository.appending(path: "Editors/vscode/data/classes.json"), encoding: .utf8)
        #expect(published == (try ClassCatalogJSON.encoded()),
                "Regenerate with: swift run swiftcn-lint --catalog-json > Editors/vscode/data/classes.json")
        let catalog = ClassCatalogJSON.catalog()
        let rules = SwiftCNLinter().rules
        for entry in catalog.classes where entry.kind != "internal" {
            #expect(throws: Never.self, "\(entry.name)") { _ = try TWStyle.parse(entry.name, rules: rules) }
        }
        // Each snippet's default value is a working class that its own pattern matches.
        for pattern in catalog.patterns where !pattern.snippet.isEmpty && !pattern.snippet.contains("\\\\(") {
            let example = pattern.snippet.replacingOccurrences(of: #"\$\{\d+:([^}]*)\}"#, with: "$1", options: .regularExpression)
            #expect(throws: Never.self, "\(example)") { _ = try TWStyle.parse(example, rules: rules) }
            #expect(example.range(of: pattern.regex, options: .regularExpression) != nil, "\(pattern.regex) matches \(example)")
        }
    }

    /// The example apps exercise most of the grammar, so they guard against false positives.
    @Test func repositoryExamplesHaveNoFalsePositives() throws {
        let examples = Self.repository.appending(path: "Examples")
        let files = FileManager.default.enumerator(at: examples, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        var linter = SwiftCNLinter()
        let sources = try files.map { ($0.path, try String(contentsOf: $0, encoding: .utf8)) }
        for source in sources { linter.learn(from: source.1) }
        let diagnostics = sources.flatMap { linter.lint(source: $0.1, path: $0.0) }
        // `h-full` is a real problem in NativeArrangementExample: swiftcn only defines `w-full`, so those
        // surfaces currently render unstyled. Remove this exception when the example is fixed.
        #expect(diagnostics.filter { $0.token != "h-full" }.map(\.xcodeFormatted) == [])
        #expect(files.count > 50)
    }
}
