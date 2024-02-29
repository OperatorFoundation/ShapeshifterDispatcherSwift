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
        .package(url: "https://github.com/OperatorFoundation/Chord", from: "0.1.4"),
        .package(url: "https://github.com/OperatorFoundation/Dandelion", from: "0.1.0"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", from: "0.1.1"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", from: "0.1.2"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift", from: "2.0.1"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", from: "5.0.2"),
        .package(url: "https://github.com/OperatorFoundation/Starbridge", from: "1.2.0"),
        .package(url: "https://github.com/OperatorFoundation/Straw", from: "1.0.3"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", from: "1.2.11"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsync", from: "0.1.4"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionAsyncNametag", from: "1.0.0")
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
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(
            name: "ShapeshifterDispatcherSwiftTests",
            dependencies: ["ShapeshifterDispatcherSwift"]),
    ]
)
