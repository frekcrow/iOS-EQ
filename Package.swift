// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "EqualizerApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "EqualizerEngine",
            targets: ["EqualizerEngine"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EqualizerEngine",
            dependencies: [],
            path: "EqualizerApp",
            exclude: [
                "App/Info.plist",
                "Assets.xcassets",
                "Preview Content"
            ]
        ),
        .testTarget(
            name: "EqualizerAppTests",
            dependencies: ["EqualizerEngine"],
            path: "EqualizerAppTests"
        )
    ]
)
