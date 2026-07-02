// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "ans-sdk-swift",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "ANS", targets: ["ANS"]),
        .library(name: "ANSEmbedded", targets: ["ANSEmbedded"]),
    ],
    targets: [
        .target(name: "ANS"),
        .target(name: "ANSEmbedded"),
        .testTarget(name: "ANSTests", dependencies: ["ANS"]),
        .testTarget(name: "ANSEmbeddedTests", dependencies: ["ANSEmbedded"]),
    ]
)
