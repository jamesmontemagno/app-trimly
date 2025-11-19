// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Trimly",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Trimly",
            targets: ["Trimly"]),
    ],
    targets: [
        .target(
            name: "Trimly"),
        .testTarget(
            name: "TrimlyTests",
            dependencies: ["Trimly"]),
    ]
)
