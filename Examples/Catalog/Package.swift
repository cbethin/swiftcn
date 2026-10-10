// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftCNCatalog",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(name: "SwiftCNCatalog", dependencies: [.product(name: "SwiftCN", package: "swiftcn")]),
        .testTarget(name: "SwiftCNCatalogTests", dependencies: ["SwiftCNCatalog"])
    ]
)
