// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TMGParseLiveQuery",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Starscream",
            targets: ["StarscreamWrapper"]),
        .library(
            name: "ParseCore",
            targets: ["ParseCoreWrapper"]),
        .library(
            name: "TMGParseLiveQuery",
            targets: ["TMGParseLiveQueryCoreWrapper"]),
    ],
    targets: [
        .target(name: "StarscreamWrapper",
                dependencies: [
                    .target(name: "Starscream"),
                ]),
        .target(name: "ParseCoreWrapper",
                dependencies: [
                    .target(name: "ParseCore"),
                    .target(name: "Bolts"),
                ]),
        .target(name: "TMGParseLiveQueryCoreWrapper",
                dependencies: [
                    .target(name: "TMGParseLiveQuery"),
                    .target(name: "BoltsSwift"),
                ]),
        // Parse Dependencies
        .binaryTarget(
            name: "ParseCore",
            url: "https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX/raw/xcframework/Frameworks/ParseCore.zip",
            checksum: "cea6d5b2a16b614a3c1ba07f22f2a412a9785819e3c6facb9ce4ea00db1ac200"
        ),
        .binaryTarget(
            name: "TMGParseLiveQuery",
            url: "https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX/raw/xcframework/Frameworks/TMGParseLiveQuery.zip",
            checksum: "4f2fc26274cff837bf2f07cfb51a72b57c96264299345bb0963749c173ff0d87"
        ),
        .binaryTarget(
            name: "Starscream",
            url: "https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX/raw/d3dd16dd76bd8d686cb6eabae96ac855e1a09804/Frameworks/Starscream.zip",
            checksum: "07c9eee55d96924fec04ed5bde6386e02f4dc227d0cd9a7622365370aac6fbb3"
        ),
        .binaryTarget(
            name: "Bolts",
            url: "https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX/raw/xcframework/Frameworks/Bolts.zip",
            checksum: "266ef2e24acfe57f97dc6638f870c0173f98e24a8bd2b5bd7fbf877c60618528"
        ),
        .binaryTarget(
            name: "BoltsSwift",
            url: "https://github.com/themeetgroup/ParseLiveQuery-iOS-OSX/raw/xcframework/Frameworks/BoltsSwift.zip",
            checksum: "4e64e4db55e9eac38d3a75a1462a87a1de250c97491489d84b43cb896585e935"
        ),
    ]
)
