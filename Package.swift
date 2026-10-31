// swift-tools-version: 5.9
import PackageDescription

// Enables `swift test` for the portable domain model on macOS or Linux.
// The app itself is built from OzDoro.xcodeproj.
let package = Package(
    name: "OzDoroCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "OzDoroCore", targets: ["OzDoroCore"])
    ],
    targets: [
        .target(name: "OzDoroCore", path: "OzDoro/Core"),
        .testTarget(name: "OzDoroCoreTests", dependencies: ["OzDoroCore"], path: "Tests/OzDoroCoreTests"),
    ]
)
