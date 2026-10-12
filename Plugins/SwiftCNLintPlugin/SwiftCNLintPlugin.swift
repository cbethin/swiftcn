import Foundation
import PackagePlugin

/// Checks swiftcn class strings in a target's Swift files on every build. Invalid classes appear
/// as build errors on the line that contains them.
///
/// The tool writes a comment-only Swift file when the check passes. Compiling that file is what
/// makes the build system run the check whenever a source file changes.
@main
struct SwiftCNLintPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        let inputs = target.sourceFiles(withSuffix: "swift").map(\.url)
        let config = existingFile(named: "swiftcn-lint.json", in: [target.directoryURL, context.package.directoryURL])
        return [lintCommand(tool: try context.tool(named: "swiftcn-lint").url, inputs: inputs, config: config,
                            output: context.pluginWorkDirectoryURL.appending(path: "SwiftCNLint+\(target.name).swift"))]
    }
}

private func existingFile(named name: String, in directories: [URL]) -> URL? {
    directories.map { $0.appending(path: name) }.first { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
}

private func lintCommand(tool: URL, inputs: [URL], config: URL?, output: URL) -> Command {
    var arguments = inputs.map { $0.path(percentEncoded: false) }
    if let config { arguments += ["--config", config.path(percentEncoded: false)] }
    arguments += ["--output", output.path(percentEncoded: false)]
    return .buildCommand(displayName: "Checking swiftcn classes", executable: tool, arguments: arguments,
                         inputFiles: inputs + (config.map { [$0] } ?? []), outputFiles: [output])
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftCNLintPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputs = target.inputFiles.filter { $0.url.pathExtension == "swift" }.map(\.url)
        let config = existingFile(named: "swiftcn-lint.json", in: [context.xcodeProject.directoryURL])
        return [lintCommand(tool: try context.tool(named: "swiftcn-lint").url, inputs: inputs, config: config,
                            output: context.pluginWorkDirectoryURL.appending(path: "SwiftCNLint+\(target.displayName).swift"))]
    }
}
#endif
