// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ReactiveRepo",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v3),
    ],
    products: [
        .library(name: "ReactiveRepo",
                 targets: ["ReactiveRepo"]),
    ],
    targets: [
        .target(name: "ReactiveRepo"),
    ],
    swiftLanguageVersions: [.v5]
)
