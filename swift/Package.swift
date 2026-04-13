// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bap-swift",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
    products: [
        .executable(name: "Bap", targets: ["Bap"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/orlandos-nl/swift-json.git", from: "2.0.0"),
        .package(
            url: "https://github.com/apple/swift-configuration.git", from: "1.0.0",
            traits: [.defaults, "CommandLineArguments"]),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.1"),
        .package(url: "https://github.com/apple/swift-system-metrics", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-prometheus.git", from: "2.0.0"),
        .package(url: "https://github.com/damuellen/xlsxwriter.swift", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Bap",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "Prometheus", package: "swift-prometheus"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "IkigaJSON", package: "swift-json"),
                .product(name: "SystemMetrics", package: "swift-system-metrics"),
                .product(name: "xlsxwriter", package: "xlsxwriter.swift"),

            ],
            path: "Sources/App",
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "BapTests",
            dependencies: [
                .byName(name: "Bap"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            path: "Tests/AppTests"
        ),
    ]
)
