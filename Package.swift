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
    ],
    targets: [
        .target(name: "ANS"),
        .testTarget(name: "ANSTests", dependencies: ["ANS"]),
    ]
)
