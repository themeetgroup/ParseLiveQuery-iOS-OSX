// swift-tools-version: 5.10
import PackageDescription

// Local Swift package vending the vendored binary dependencies for TMGParseLiveQuery.
// The xcframeworks are committed as `.zip` archives (keeps the repo to 3 binary files instead of
// hundreds, so the PR stays reviewable) and referenced directly as binary targets — no unzip step.
let package = Package(
    name: "LiveQueryDependencies",
    products: [
        .library(
            name: "LiveQueryDependencies",
            targets: ["Bolts", "BoltsSwift", "TMGParseCore"]
        )
    ],
    targets: [
        .binaryTarget(name: "Bolts", path: "Bolts.xcframework.zip"),
        .binaryTarget(name: "BoltsSwift", path: "BoltsSwift.xcframework.zip"),
        .binaryTarget(name: "TMGParseCore", path: "TMGParseCore.xcframework.zip"),
    ]
)
