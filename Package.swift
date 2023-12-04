// swift-tools-version:5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShapeshifterDispatcherSwift",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/OperatorFoundation/Chord", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Dandelion", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Starbridge", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "ShapeshifterDispatcherSwift",
            dependencies: [
                "Chord",
                "ReplicantSwift",
                "Nametag",
                "ShadowSwift",
                "Starbridge",
                "Transmission",
                "TransmissionAsync",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "DandelionServer", package: "Dandelion"),
                .product(name: "TransmissionAsyncNametag", package: "Nametag")]),
        .executableTarget(
            name: "ShapeshifterConfigs",
            dependencies: [
                "Dandelion",
                "Gardener",
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "ShapeshifterDispatcherSwiftTests",
            dependencies: ["ShapeshifterDispatcherSwift"]),
    ]
)
