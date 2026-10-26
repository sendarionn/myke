// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "myke",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MykeInput", targets: ["MykeInput"])
    ],
    dependencies: [
        .package(url: "https://github.com/azooKey/AzooKeyKanaKanjiConverter", exact: "0.11.2")
    ],
    targets: [
        .target(
            name: "MykeInput",
            dependencies: [
                .product(
                    name: "KanaKanjiConverterModuleWithDefaultDictionary",
                    package: "AzooKeyKanaKanjiConverter"
                )
            ],
            path: "Shared",
            exclude: ["KeyboardView.swift"],
            sources: ["InputEngine.swift", "KanaKanjiConversionEngine.swift"]
        ),
        .testTarget(
            name: "MykeInputTests",
            dependencies: ["MykeInput"],
            path: "Tests"
        )
    ]
)
