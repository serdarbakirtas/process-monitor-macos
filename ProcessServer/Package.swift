// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ProcessServer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/grpc/grpc-swift.git",
            from: "1.23.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "ProcessServer",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
            ],
            path: "Sources/ProcessServer"
        ),
        .testTarget(
            name: "ProcessServerTests",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
            ],
            path: "Tests/ProcessServerTests"
        ),
    ]
)
