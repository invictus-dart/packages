// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mars_logging",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "mars", targets: ["mars"]),
        .library(name: "mars-logging", targets: ["mars_logging"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(name: "tencent_mars", path: "Frameworks/mars.xcframework"),
        .target(
            name: "mars_md5",
            path: "Sources/mars_md5",
            publicHeadersPath: "."
        ),
        .target(
            name: "mars",
            dependencies: [
                .target(name: "tencent_mars"),
                .target(name: "mars_md5")
            ],
            path: "Sources/mars",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("Component")],
            cxxSettings: [.headerSearchPath("Component")],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("Foundation"),
                .linkedLibrary("resolv.9"),
                .linkedLibrary("z"),
            ]
        ),
        .target(
            name: "mars_logging",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .target(name: "mars"),
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        ),
    ]
)
