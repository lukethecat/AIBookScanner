// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIBookScanner",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AIBookScanner",
            targets: ["AIBookScanner"])
    ],
    dependencies: [
        // 本地依赖
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "AIBookScanner",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "AIBookScanner",
            resources: [
                .process("Resources"),
                .copy("Models"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"]),
            ]
        ),
        .testTarget(
            name: "AIBookScannerTests",
            dependencies: ["AIBookScanner"],
            path: "Tests"
        ),
    ]
)
