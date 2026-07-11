// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClamshellReady",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClamshellReady", targets: ["ClamshellReady"]),
        .executable(name: "ClamshellReadyLidDaemon", targets: ["ClamshellReadyLidDaemon"])
    ],
    targets: [
        .executableTarget(name: "ClamshellReady"),
        .executableTarget(name: "ClamshellReadyLidDaemon")
    ]
)
