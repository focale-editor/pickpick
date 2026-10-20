// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pickpick",
    platforms: [.macOS("12.0")],
    products: [.library(name: "pickpick", targets: ["pickpick"])],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "pickpick",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            linkerSettings: [.linkedFramework("AppKit")]
        )
    ]
)
