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
            name: "t_position",
            targets: ["PositionTests"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Schema.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Position",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
            ],
        ),

        .executableTarget(
            name: "PositionTests",
            dependencies: [
                "Position",
                .product(name: "Schema", package: "Schema"),
                .product(name: "Testing", package: "Testing")
            ],
            path: "Testing/PositionTests"
        )
    ]
)
