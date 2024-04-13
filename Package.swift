// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TMGParseLiveQuery",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Starscream",
            targets: ["Starscream"]),
        .library(
            name: "ParseCore",
            targets: ["ParseCore", "Bolts"]),
        .library(
            name: "TMGParseLiveQuery",
            targets: ["TMGParseLiveQuery", "BoltsSwift"]),
    ],
    targets: [
        .binaryTarget(
            name: "ParseCore",
            path: "Frameworks/ParseCore.xcframework"
        ),
        .binaryTarget(
            name: "TMGParseLiveQuery",
            path: "Frameworks/TMGParseLiveQuery.xcframework"
        ),
        .binaryTarget(
            name: "Starscream",
            path: "Frameworks/Starscream.xcframework"
        ),
        .binaryTarget(
            name: "Bolts",
            path: "Frameworks/Bolts.xcframework"
        ),
        .binaryTarget(
            name: "BoltsSwift",
            path: "Frameworks/BoltsSwift.xcframework"
        ),
    ]
)
