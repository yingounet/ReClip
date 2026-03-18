// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReClip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ReClip", targets: ["ReClip"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ReClip",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin"),
            ],
            path: "ReClip",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "ReClipTests",
            dependencies: ["ReClip"],
            path: "Tests/ReClipTests"
        ),
    ]
)
