// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FileDrop",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "FileDrop",
            path: "Sources/FileDrop"
        )
    ]
)
