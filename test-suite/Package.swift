// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test-suite",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "TestSuite", targets: ["TestSuite"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(
            url: "https://github.com/hummingbird-community/hummingbird-elementary.git",
            from: "0.4.0"),
        .package(url: "https://github.com/elementary-swift/elementary-htmx.git", from: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "TestSuite",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdElementary", package: "hummingbird-elementary"),
                .product(name: "ElementaryHTMX", package: "elementary-htmx"),
                .product(name: "ElementaryHTMXSSE", package: "elementary-htmx"),
            ],
            path: "Sources/App",
            resources: [
                .copy("public")
            ],
        ),
        .testTarget(
            name: "TestSuiteTests",
            dependencies: [
                .byName(name: "TestSuite"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            path: "Tests/AppTests"
        ),
    ]
)
