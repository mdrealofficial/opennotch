// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OpenNotch",
            targets: ["OpenNotch"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OpenNotch",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "OpenNotchTests",
            dependencies: ["OpenNotch"],
            path: "Tests"
        )
    ]
)
