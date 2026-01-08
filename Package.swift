// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Radyoozu",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Radyoozu",
            path: "Radyoozu",
            exclude: ["Info.plist"],
            resources: [.copy("Resources")]
        )
    ]
)
