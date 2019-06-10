// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ASNetworking",
    products: [
        .library(
            name: "ASNetworking",
            targets: ["ASNetworking"]),
    ],
    targets: [
        .target(
            name: "ASNetworking",
            dependencies: []),
        .testTarget(
            name: "ASNetworkingTests",
            dependencies: ["ASNetworking"]),
    ],
	swiftLanguageVersions: [.v5]
)
