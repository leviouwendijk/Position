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
    ],
    dependencies: [
        .package(url: "https://github.com/swift-lco/Schema.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Position",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
            ],
        ),
    ]
)
