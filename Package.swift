// swift-tools-version: 5.8.0

import PackageDescription

let package = Package(
    name: "swift-nibbles",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "Extensions", targets: ["Extensions"]),
    ],
    targets: [
        .target(name: "Extensions"),
        .testTarget(name: "ExtensionsTests", dependencies: ["Extensions"]),
    ]
)
