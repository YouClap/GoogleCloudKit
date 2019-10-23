// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "GoogleCloudKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "GoogleCloudKit",
            targets: ["GoogleCloudKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.14.1"),
        .package(url: "https://github.com/vapor/http.git", from: "3.2.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GoogleCloudKit",
            dependencies: ["JWT", "NIO", "HTTP"]),
        .testTarget(
            name: "GoogleCloudKitTests",
            dependencies: ["GoogleCloudKit"]),
    ]
)
