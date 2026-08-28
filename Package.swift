// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ImageBench",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ImageBench", targets: ["ImageBench"])
    ],
    targets: [
        .executableTarget(
            name: "ImageBench",
            path: "Sources/ImageBench",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ImageBenchTests",
            dependencies: ["ImageBench"],
            path: "Tests/ImageBenchTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
