// swift-tools-version: 5.9.0

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
        .library(name: "Exchange", targets: ["Exchange"]),
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "Fuse", targets: ["Fuse"]),
        .library(name: "Identified", targets: ["Identified"]),
        .library(name: "SharedState", targets: ["SharedState"]),
        .library(name: "Stash", targets: ["Stash"]),
        .library(name: "StateBinding", targets: ["StateBinding"]),
        .plugin(name: "Create TCA Feature", targets: ["Create TCA Feature"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
    ],
    targets: [
        .target(name: "Exchange"),
        .testTarget(name: "ExchangeTests", dependencies: ["Exchange"]),
        
        .target(name: "Extensions"),
        .testTarget(name: "ExtensionsTests", dependencies: ["Extensions"]),
        
        .target(name: "Fuse"),
        .testTarget(name: "FuseTests", dependencies: ["Fuse"]),
        
        .target(name: "Identified"),
        .testTarget(name: "IdentifiedTests", dependencies: ["Identified"]),
        
        .target(name: "SharedState", dependencies: ["Fuse", .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),]),
        .testTarget(name: "SharedStateTests", dependencies: ["SharedState"]),
        
        .target(name: "Stash"),
        .testTarget(name: "StashTests", dependencies: ["Stash"]),

        .target(name: "StateBinding"),
        .testTarget(name: "StateBindingTests", dependencies: ["StateBinding", .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")]),

        .plugin(
            name: "Create TCA Feature",
            capability: .command(
                intent: .custom(
                    verb: "create-tca-feature",
                    description: "Generates the source files for a new TCA feauture."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Generates source code."),
                ]
            )
        )
    ]
)
