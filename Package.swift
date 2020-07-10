// swift-tools-version:5.2
import PackageDescription

let package = Package(
	name: "XCGLogger",
	targets: [
        .target(
            name: "XCGLogger",
            dependencies: ["ObjcExceptionBridging"]
        ),
        .target(
            name: "ObjcExceptionBridging",
            dependencies: []
        ),
//		Target(name: "XCGLogger", dependencies: ["ObjcExceptionBridging"]),
//		Target(name: "ObjcExceptionBridging")
	]
)
