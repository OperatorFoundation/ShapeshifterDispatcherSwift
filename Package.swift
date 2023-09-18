// swift-tools-version:5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShapeshifterDispatcherSwift",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "git@github.com:apple/swift-argument-parser.git", from: "1.2.3"),
        .package(url: "git@github.com:OperatorFoundation/Dandelion.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/ReplicantSwift.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/ShadowSwift.git", branch: "main"),
        .package(url: "git@github.com:OperatorFoundation/Starbridge.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "ShapeshifterDispatcherSwift",
            dependencies: [
                "Dandelion",
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .executableTarget(
            name: "ShapeshifterConfigs",
            dependencies: [
                "Dandelion",
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "ShapeshifterDispatcherSwiftTests",
            dependencies: ["ShapeshifterDispatcherSwift"]),
    ]
)
