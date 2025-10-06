// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "breadcrumbs",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "breadcrumbs-server",
            targets: ["breadcrumbs-server"]
        ),
    ],
    dependencies: [
        // OpenAI package for AI model integration
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.4.6"),
        
        // Vapor web framework for HTTP server
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        
        // SwiftNIO for high-performance networking (used by Vapor)
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),

        // Swift ArgumentParser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "breadcrumbs-server",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "breadcrumbs"
        ),
    ]
)
