// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShapeshifterDispatcherSwift",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url:"https://github.com/OperatorFoundation/ReplicantSwift.git", branch: "main"),
        .package(url:"https://github.com/OperatorFoundation/ShadowSwift.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.0.3"),
    ],
    targets: [
        .executableTarget(
            name: "ShapeshifterDispatcherSwift",
            dependencies: [
                "ReplicantSwift",
                "ShadowSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "ShapeshifterDispatcherSwiftTests",
            dependencies: ["ShapeshifterDispatcherSwift"]),
    ]
)
