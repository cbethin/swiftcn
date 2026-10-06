// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swiftcn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SwiftCN", targets: ["SwiftCN"])],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.6")
    ],
    targets: [
        .target(name: "SwiftCN"),
        .testTarget(name: "SwiftCNTests", dependencies: ["SwiftCN"]),
        .testTarget(name: "SwiftCNVisualTests", dependencies: [
            "SwiftCN", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
        ], exclude: ["__Snapshots__"])
    ]
)
