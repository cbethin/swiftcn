import Foundation
import PackagePlugin

/// `swift package swiftcn-lint [--target Name…] [--format json] [--warnings]`
///
/// Checks swiftcn class strings without building the app. Coding agents can run it after each edit.
@main
struct SwiftCNLintCommand: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var extractor = ArgumentExtractor(arguments)
        let names = extractor.extractOption(named: "target")
        let targets = names.isEmpty ? context.package.targets : try context.package.targets(named: names)
        let files = targets.compactMap { $0 as? SourceModuleTarget }
            .flatMap { $0.sourceFiles(withSuffix: "swift").map(\.url) }
        let config = context.package.directoryURL.appending(path: "swiftcn-lint.json")
        try run(tool: try context.tool(named: "swiftcn-lint").url, files: files, config: config,
                options: extractor.remainingArguments)
    }
}

private func run(tool: URL, files: [URL], config: URL, options: [String]) throws {
    var arguments = files.map { $0.path(percentEncoded: false) } + options
    if FileManager.default.fileExists(atPath: config.path(percentEncoded: false)) {
        arguments += ["--config", config.path(percentEncoded: false)]
    }
    let process = Process()
    process.executableURL = tool
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        Diagnostics.error("swiftcn-lint found invalid classes.")
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftCNLintCommand: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let names = Set(extractor.extractOption(named: "target"))
        let targets = context.xcodeProject.targets.filter { names.isEmpty || names.contains($0.displayName) }
        let files = targets.flatMap { $0.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url) }
        try run(tool: try context.tool(named: "swiftcn-lint").url, files: files,
                config: context.xcodeProject.directoryURL.appending(path: "swiftcn-lint.json"),
                options: extractor.remainingArguments)
    }
}
#endif
