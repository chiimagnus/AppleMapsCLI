// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "applmaps",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "applmaps",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "applmapsTests",
            dependencies: ["applmaps"]
        )
    ],
    swiftLanguageModes: [.v6]
)
