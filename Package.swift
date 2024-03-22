// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShapeshifterDispatcherSwift",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/OperatorFoundation/Chord", from: "0.1.5"),
        .package(url: "https://github.com/OperatorFoundation/Dandelion", from: "0.1.1"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", from: "0.1.2"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", from: "0.1.3"),
        .package(url: "https://github.com/OperatorFoundation/Omni", from: "1.0.0"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift", from: "2.0.2"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", from: "5.0.3"),
        .package(url: "https://github.com/OperatorFoundation/Starbridge", from: "1.2.1"),
        .package(url: "https://github.com/OperatorFoundation/Straw", from: "1.0.4"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", from: "1.2.12"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", from: "0.1.5"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsyncNametag", from: "1.0.1")
    ],
    targets: [
        .executableTarget(
            name: "ShapeshifterDispatcherSwift",
            dependencies: [
                "Chord",
                "Nametag",
                "ReplicantSwift",
                "Omni",
                "ShadowSwift",
                "Starbridge",
                "Straw",
                "Transmission",
                "TransmissionAsync",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "DandelionServer", package: "Dandelion"),
                .product(name: "TransmissionAsyncNametag", package: "TransmissionAsyncNametag")]),
        .executableTarget(
            name: "ShapeshifterConfigs",
            dependencies: [
                "Dandelion",
                "Gardener",
                "Omni",
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "ShapeshifterDispatcherSwiftTests",
            dependencies: ["ShapeshifterDispatcherSwift"]),
    ]
)
