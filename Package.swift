// swift-tools-version: 6.2
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
        
        // Swift Async DNS Resolver for DNS queries - temporarily disabled due to CI issues
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
                "breadcrumbsApp.swift",
                "ContentView.swift",
                "Views/ChatView.swift",
                "Views/SettingsView.swift",
                "Views/ServerSettingsView.swift",
                "ViewModels/ChatViewModel.swift",
                "Services/ServiceManager.swift",
                "Services/VaporServer.swift",
                "Tools/AppCheckerTool.swift",
                "Tools/SystemDiagnosticTool.swift",
                "Item.swift"
            ],
            swiftSettings: [
                .define("SWIFT_APPROACHABLE_CONCURRENCY"),
            ]
        ),
        .testTarget(
            name: "breadcrumbsTests",
            dependencies: [
                "breadcrumbs"
            ],
            path: "breadcrumbsTests",
            exclude: [
                "README.md",
                "ViewModels/ChatViewModelTests.swift",
                "Integration/AppIntegrationTests.swift",
                "Models/ItemTests.swift"
            ],
            swiftSettings: [
                .define("UNIT_TESTS"),
                .define("SWIFT_APPROACHABLE_CONCURRENCY"),
            ]
        ),
    ]
)
