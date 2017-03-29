import PackageDescription

let package = Package(
	name: "XCGLogger",
	targets: [
		Target(name: "XCGLogger", dependencies: ["ObjcExceptionBridging"]),
		Target(name: "ObjcExceptionBridging")
	]
)
