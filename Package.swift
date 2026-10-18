// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swiftcn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SwiftCN", targets: ["SwiftCN"]),
        // Build-time checks for class strings. The library itself has no dependencies.
        .executable(name: "swiftcn-lint", targets: ["swiftcn-lint"]),
        .plugin(name: "SwiftCNLintPlugin", targets: ["SwiftCNLintPlugin"]),
        .plugin(name: "SwiftCNLintCommand", targets: ["SwiftCNLintCommand"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.6")
    ],
    targets: [
        .target(name: "SwiftCN"),
        .target(name: "SwiftCNLint", dependencies: ["SwiftCN"]),
        .executableTarget(name: "swiftcn-lint", dependencies: ["SwiftCNLint"]),
        .plugin(name: "SwiftCNLintPlugin", capability: .buildTool(), dependencies: ["swiftcn-lint"]),
        .plugin(name: "SwiftCNLintCommand",
                capability: .command(intent: .custom(verb: "swiftcn-lint", description: "Check swiftcn class strings")),
                dependencies: ["swiftcn-lint"]),
        .testTarget(name: "SwiftCNLintTests", dependencies: ["SwiftCNLint"]),
        .executableTarget(name: "SwiftCNComponentGallery", dependencies: ["SwiftCN"], path: "Examples/Components/Sources"),
        .testTarget(name: "SwiftCNTests", dependencies: ["SwiftCN"]),
        .testTarget(name: "SwiftCNVisualTests", dependencies: [
            "SwiftCN", "SwiftCNComponentGallery", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
        ], exclude: ["__Snapshots__"])
    ]
)
