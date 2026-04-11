// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MenuBarNetSpeed",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MenuBarNetSpeed",
            targets: ["MenuBarNetSpeed"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MenuBarNetSpeed",
            dependencies: ["NetSpeedKit"]
        ),
        .target(
            name: "NetSpeedKit",
            path: "Sources/NetSpeedKit"
        ),
        .testTarget(
            name: "NetSpeedKitTests",
            dependencies: ["NetSpeedKit"],
            path: "Tests/NetSpeedKitTests"
        )
    ]
)
