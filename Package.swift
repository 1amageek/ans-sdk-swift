// swift-tools-version: 6.3

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
    dependencies: [
        .package(
            url: "https://github.com/1amageek/swift-crypto.git",
            revision: "65cc0779dbf34edf10dce27ddac6e60aeb258b71"
        ),
    ],
    targets: [
        .target(
            name: "ANS",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
        .testTarget(
            name: "ANSTests",
            dependencies: ["ANS"]
        ),
    ]
)
