// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Up",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "UpCore"),
        .executableTarget(name: "Up", dependencies: ["UpCore"]),
        .testTarget(name: "UpCoreTests", dependencies: ["UpCore"]),
    ]
)
