// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "breadcrumbs",
    platforms: [
        .macOS(.v14)  // SPM supports up to v14, but Xcode project targets 15.0
    ],
    products: [
        .library(
            name: "breadcrumbs",
            targets: ["breadcrumbs"]
        ),
    ],
    dependencies: [
        // OpenAI package for AI model integration - match Xcode project version
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0"),
        
        // Vapor web framework for HTTP server - match Xcode project version
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),

        // Swift ArgumentParser for CLI - match Xcode project version
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
        
        // Swift Async DNS Resolver for DNS queries - match Xcode project version
        .package(url: "https://github.com/apple/swift-async-dns-resolver", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "breadcrumbs",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncDNSResolver", package: "swift-async-dns-resolver"),
            ],
            path: "breadcrumbs",
            exclude: [
                "Info.plist",
                "breadcrumbs.entitlements", 
                "Assets.xcassets",
                "breadcrumbsApp.swift"
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility"),
                .define("SWIFT_APPROACHABLE_CONCURRENCY"),
                .define("SWIFT_DEFAULT_ACTOR_ISOLATION"),
            ]
        ),
        .testTarget(
            name: "breadcrumbsTests",
            dependencies: [
                "breadcrumbs"
            ],
            path: "breadcrumbsTests",
            exclude: [
                "README.md"
            ],
            swiftSettings: [
                .define("UNIT_TESTS"),
                .define("SWIFT_APPROACHABLE_CONCURRENCY"),
            ]
        ),
    ]
)
