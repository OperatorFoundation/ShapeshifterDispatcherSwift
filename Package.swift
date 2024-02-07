// swift-tools-version:5.7.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShapeshifterDispatcherSwift",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3"),
        .package(url: "https://github.com/OperatorFoundation/Chord.git", branch: "0.1.1"),
        .package(url: "https://github.com/OperatorFoundation/Dandelion.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Gardener.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Nametag.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Starbridge.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/Transmission.git", branch: "release"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync.git", branch: "release")
    ],
    targets: [
        .executableTarget(
            name: "ShapeshifterDispatcherSwift",
            dependencies: [
                "Chord",
                "Nametag",
                "ReplicantSwift",
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
