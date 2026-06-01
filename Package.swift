// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OccultSuccess",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OccultSuccess", targets: ["OccultSuccessApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OccultSuccessApp",
            dependencies: [],
            path: "Sources/OccultSuccessApp"
        ),
        .testTarget(
            name: "OccultSuccessAppTests",
            dependencies: ["OccultSuccessApp"]
        )
    ]
)
