// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PositionTests",
    products: [
        .executable(
            name: "t_position",
            targets: ["PositionTests"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Schema.git", branch: "master"),
        .package(url: "https://github.com/swift-tooling/Testing.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [

        .executableTarget(
            name: "PositionTests",
            dependencies: [
                .product(name: "Position", package: "Position"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Testing", package: "Testing")
            ]
        )
    ]
)
