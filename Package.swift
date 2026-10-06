// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Position",
    products: [
        .library(
            name: "Position",
            targets: ["Position"]
        ),
        .executable(
            name: "ptest",
            targets: ["PositionTests"]
        ),
    ],
    targets: [
        .target(
            name: "Position"
        ),
        .executableTarget(
            name: "PositionTests",
            dependencies: [
                "Position",
            ],
            path: "Testing/PositionTests"
        ),
    ]
)
