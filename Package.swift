// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "EqualizerApp",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
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
                "App/EqualizerApp.entitlements",
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
