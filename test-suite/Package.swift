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
        .package(
            url: "https://github.com/hummingbird-project/hummingbird-valkey.git", from: "0.1.0"),
        .package(url: "https://github.com/hummingbird-project/swift-jobs.git", from: "1.0.0"),
        .package(
            url: "https://github.com/hummingbird-project/swift-jobs-valkey.git", from: "1.0.0-rc.2"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
    ],
    targets: [
        .target(
            name: "TestSuiteLibrary",
            dependencies: [
                .product(name: "Jobs", package: "swift-jobs"),
                .product(name: "JobsValkey", package: "swift-jobs-valkey"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            path: "Sources/Library"
        ),
        .target(
            name: "TestSuiteCli",
            dependencies: [
                .byName(name: "TestSuiteLibrary"),
            ],
            path: "Sources/Cli"
        ),
        .executableTarget(
            name: "TestSuite",
            dependencies: [
                .byName(name: "TestSuiteLibrary"),
                .byName(name: "TestSuiteCli"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdElementary", package: "hummingbird-elementary"),
                .product(name: "ElementaryHTMX", package: "elementary-htmx"),
                .product(name: "ElementaryHTMXSSE", package: "elementary-htmx"),
                .product(name: "HummingbirdValkey", package: "hummingbird-valkey"),
                .product(name: "Jobs", package: "swift-jobs"),
                .product(name: "JobsValkey", package: "swift-jobs-valkey"),
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
