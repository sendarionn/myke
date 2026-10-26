// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "myke",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MykeInput", targets: ["MykeInput"])
    ],
    targets: [
        .target(
            name: "MykeInput",
            path: "Shared",
            exclude: ["KeyboardView.swift"],
            sources: ["InputEngine.swift"]
        ),
        .testTarget(
            name: "MykeInputTests",
            dependencies: ["MykeInput"],
            path: "Tests"
        )
    ]
)
