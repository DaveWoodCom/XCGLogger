// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCGLogger",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "XCGLogger",
            targets: ["XCGLogger"]),
        .library(
            name: "ObjcExceptionBridging",
            targets: ["ObjcExceptionBridging"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "XCGLogger",
            dependencies: ["ObjcExceptionBridging"],
            path: "Sources/XCGLogger",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "XCGLoggerTests",
            dependencies: ["XCGLogger"]),
        .target(
            name: "ObjcExceptionBridging",
            dependencies: [],
            path: "Sources/ObjcExceptionBridging",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]),
    ]
)
