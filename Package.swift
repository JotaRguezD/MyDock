// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyDock",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "MyDock", path: "Sources/MyDock")
    ]
)
