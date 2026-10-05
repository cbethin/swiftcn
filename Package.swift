// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swiftcn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SwiftCN", targets: ["SwiftCN"])],
    targets: [
        .target(name: "SwiftCN"),
        .testTarget(name: "SwiftCNTests", dependencies: ["SwiftCN"])
    ]
)
