// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HeadlessMacBookTools",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "HeadlessMacBookTools", targets: ["HeadlessMacBookTools"])],
    targets: [
        .executableTarget(name: "HeadlessMacBookTools"),
        .executableTarget(
            name: "ClamshellReadyLidDaemon",
            path: "Sources/HeadlessMacBookToolsLidDaemon"
        )
    ]
)
