// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTPAssertion",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HTTPAssertionLogging",
            targets: ["HTTPAssertionLogging"]),
        .library(
            name: "HTTPAssertionTesting",
            targets: ["HTTPAssertionTesting"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HTTPAssertionLogging"),
        .target(
            name: "HTTPAssertionTesting",
            dependencies: ["HTTPAssertionLogging"],
            linkerSettings: [
                .linkedFramework("XCTest", .when(platforms: [.iOS]))
            ]),
        .testTarget(
            name: "HTTPAssertionTests",
            dependencies: ["HTTPAssertionLogging", "HTTPAssertionTesting"]
        ),
    ]
)
