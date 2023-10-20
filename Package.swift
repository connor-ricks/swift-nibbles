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
        .library(name: "Stash", targets: ["Stash"]),
        .plugin(name: "Create TCA Feature", targets: ["Create TCA Feature"])
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
        
        .target(name: "Stash"),
        .testTarget(name: "StashTests", dependencies: ["Stash"]),
        
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
