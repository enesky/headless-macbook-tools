// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Halftop",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Halftop", targets: ["Halftop"])],
    targets: [
        .executableTarget(name: "Halftop"),
        .executableTarget(
            name: "HalftopLidDaemon",
            path: "Sources/HalftopLidDaemon"
        )
    ]
)
