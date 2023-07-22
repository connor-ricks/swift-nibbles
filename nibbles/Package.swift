// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Nibbles",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "Cache", targets: ["Cache"]),
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "HTTPNetworking", targets: ["HTTPNetworking"]),
        .library(name: "Identified", targets: ["Identified"]),
    ],
    targets: [
        .target(name: "Cache"),
        .testTarget(name: "CacheTests", dependencies: ["Cache"]),
        
        .target(name: "Extensions"),
        .testTarget(name: "ExtensionsTests", dependencies: ["Extensions"]),
        
        .target(name: "HTTPNetworking"),
        .testTarget(name: "HTTPNetworkingTests", dependencies: ["HTTPNetworking"]),
        
        .target(name: "Identified"),
        .testTarget(name: "IdentifiedTests", dependencies: ["Identified"]),
    ]
)
