// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppleMapsCLI",
    platforms: [.macOS("15.6")],
    products: [
        .executable(name: "applemaps", targets: ["AppleMapsCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleMapsCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppleMapsCLITests",
            dependencies: ["AppleMapsCLI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
