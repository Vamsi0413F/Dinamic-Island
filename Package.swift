// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacDynamicIsland",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacDynamicIsland",
            targets: ["MacDynamicIsland"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacDynamicIsland",
            path: "Sources/MacDynamicIsland"
        ),
        .testTarget(
            name: "MacDynamicIslandTests",
            dependencies: ["MacDynamicIsland"],
            path: "Tests/MacDynamicIslandTests"
        )
    ]
)
