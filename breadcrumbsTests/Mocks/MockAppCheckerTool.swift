//
//  MockAppCheckerTool.swift
//  breadcrumbsTests
//
//  Mock implementation of AppCheckerTool for testing
//

import Foundation
@testable import breadcrumbs

/// Mock implementation of AppCheckerTool for testing purposes
final class MockAppCheckerTool: AITool, @unchecked Sendable {
    
    let name = "app_checker"
    
    let description = "Mock app checker tool for testing"
    
    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "app_name": [
                    "type": "string",
                    "description": "App name to search for"
                ],
                "bundle_identifier": [
                    "type": "string",
                    "description": "Bundle identifier to search for"
                ],
                "category": [
                    "type": "string",
                    "description": "App category filter"
                ],
                "include_system_apps": [
                    "type": "boolean",
                    "description": "Include system apps"
                ],
                "running_apps_only": [
                    "type": "boolean",
                    "description": "Running apps only"
                ],
                "max_results": [
                    "type": "integer",
                    "description": "Maximum results"
                ]
            ],
            "required": []
        ])
    }
    
    // Mock data
    var mockApps: [AppInfo] = []
    var shouldThrowError = false
    var mockError: Error = ToolError.executionFailed("Mock error")
    var lastExecutedArguments: [String: Any] = [:]
    
    func execute(arguments: [String: Any]) async throws -> String {
        lastExecutedArguments = arguments
        
        if shouldThrowError {
            throw mockError
        }
        
        // Create mock output based on arguments
        let input = parseInput(from: arguments)
        let filteredApps = filterApps(mockApps, with: input)
        
        let systemInfo = SystemInfo(
            osVersion: "macOS 14.0",
            architecture: "arm64",
            hostName: "MockMac.local",
            userName: "testuser"
        )
        
        let output = AppCheckerOutput(
            query: buildQueryString(from: input),
            totalAppsFound: filteredApps.count,
            apps: filteredApps,
            searchCriteria: input,
            timestamp: Date(),
            systemInfo: systemInfo
        )
        
        return output.toFormattedString()
    }
    
    // MARK: - Helper Methods (copied from real implementation for testing)
    
    private func parseInput(from arguments: [String: Any]) -> AppCheckerInput {
        return AppCheckerInput(
            appName: arguments["app_name"] as? String,
            bundleIdentifier: arguments["bundle_identifier"] as? String,
            category: arguments["category"] as? String,
            includeSystemApps: arguments["include_system_apps"] as? Bool ?? false,
            runningAppsOnly: arguments["running_apps_only"] as? Bool ?? false,
            maxResults: arguments["max_results"] as? Int ?? 100
        )
    }
    
    private func buildQueryString(from input: AppCheckerInput) -> String {
        var parts: [String] = []
        
        if let appName = input.appName {
            parts.append("name: \(appName)")
        }
        if let bundleId = input.bundleIdentifier {
            parts.append("bundle: \(bundleId)")
        }
        if let category = input.category {
            parts.append("category: \(category)")
        }
        if input.runningAppsOnly ?? false {
            parts.append("running only")
        }
        if input.includeSystemApps ?? false {
            parts.append("including system apps")
        }
        
        return parts.isEmpty ? "all applications" : parts.joined(separator: ", ")
    }
    
    private func filterApps(_ apps: [AppInfo], with input: AppCheckerInput) -> [AppInfo] {
        return apps.filter { app in
            // Filter by app name
            if let appName = input.appName {
                if !app.name.localizedCaseInsensitiveContains(appName) {
                    return false
                }
            }
            
            // Filter by bundle identifier
            if let bundleId = input.bundleIdentifier {
                if !app.bundleIdentifier.localizedCaseInsensitiveContains(bundleId) {
                    return false
                }
            }
            
            // Filter by category
            if let category = input.category {
                if let appCategory = app.category {
                    if !appCategory.localizedCaseInsensitiveContains(category) {
                        return false
                    }
                } else {
                    return false
                }
            }
            
            // Filter by system apps
            if !(input.includeSystemApps ?? false) && app.isSystemApp {
                return false
            }

            // Filter by running apps
            if (input.runningAppsOnly ?? false) && !app.isRunning {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Mock Configuration Methods
    
    /// Set mock apps data
    func setMockApps(_ apps: [AppInfo]) {
        mockApps = apps
    }
    
    /// Configure mock to throw error
    func setShouldThrowError(_ shouldThrow: Bool, error: Error? = nil) {
        shouldThrowError = shouldThrow
        if let error = error {
            mockError = error
        }
    }
    
    /// Get the last executed arguments
    func getLastExecutedArguments() -> [String: Any] {
        return lastExecutedArguments
    }
    
    /// Create sample mock apps for testing
    func createSampleMockApps() {
        mockApps = [
            AppInfo(
                name: "Google Chrome",
                bundleIdentifier: "com.google.Chrome",
                version: "120.0.6099.109",
                buildNumber: "120.0.6099.109",
                bundlePath: "/Applications/Google Chrome.app",
                executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                isRunning: true,
                launchDate: Date(),
                installDate: Date().addingTimeInterval(-86400),
                lastOpenedDate: Date(),
                fileSize: 200000000,
                isSystemApp: false,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: ["html", "htm"],
                urlSchemes: ["https", "http"],
                minimumSystemVersion: "10.15",
                architecture: ["x86_64", "arm64"],
                codeSigningInfo: CodeSigningInfo(
                    isSigned: true,
                    signingIdentity: "Developer ID Application: Google LLC (EQHXZ8M8AV)",
                    teamIdentifier: "EQHXZ8M8AV",
                    certificateAuthority: ["Developer ID Certification Authority"],
                    timestamp: Date(),
                    isAdHocSigned: false,
                    isHardenedRuntime: true,
                    entitlements: ["com.apple.security.cs.allow-jit": "true"]
                ),
                appStoreInfo: AppStoreInfo(
                    isAppStoreApp: false,
                    appStoreVersion: nil,
                    purchaseDate: nil,
                    originalPurchaseDate: nil,
                    isPurchased: false,
                    isFree: true
                ),
                category: "web_browsers",
                developer: "Google LLC",
                copyright: "Copyright 2023 Google LLC",
                description: "A fast, secure web browser"
            ),
            AppInfo(
                name: "Safari",
                bundleIdentifier: "com.apple.Safari",
                version: "17.1",
                buildNumber: "19618.1.15.11.23",
                bundlePath: "/Applications/Safari.app",
                executablePath: "/Applications/Safari.app/Contents/MacOS/Safari",
                isRunning: false,
                launchDate: nil,
                installDate: Date().addingTimeInterval(-2592000),
                lastOpenedDate: Date().addingTimeInterval(-3600),
                fileSize: 150000000,
                isSystemApp: true,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: ["html", "htm", "webarchive"],
                urlSchemes: ["https", "http"],
                minimumSystemVersion: "13.0",
                architecture: ["arm64"],
                codeSigningInfo: CodeSigningInfo(
                    isSigned: true,
                    signingIdentity: "Software Signing",
                    teamIdentifier: "Apple Inc.",
                    certificateAuthority: ["Apple Root CA"],
                    timestamp: Date(),
                    isAdHocSigned: false,
                    isHardenedRuntime: true,
                    entitlements: ["com.apple.security.cs.allow-jit": "true"]
                ),
                appStoreInfo: AppStoreInfo(
                    isAppStoreApp: true,
                    appStoreVersion: "17.1",
                    purchaseDate: Date().addingTimeInterval(-2592000),
                    originalPurchaseDate: Date().addingTimeInterval(-2592000),
                    isPurchased: true,
                    isFree: true
                ),
                category: "web_browsers",
                developer: "Apple Inc.",
                copyright: "Copyright 2023 Apple Inc.",
                description: "Apple's web browser"
            ),
            AppInfo(
                name: "Steam",
                bundleIdentifier: "com.valvesoftware.steam",
                version: "1.0.0.78",
                buildNumber: "1.0.0.78",
                bundlePath: "/Applications/Steam.app",
                executablePath: "/Applications/Steam.app/Contents/MacOS/steam_osx",
                isRunning: false,
                launchDate: nil,
                installDate: Date().addingTimeInterval(-604800),
                lastOpenedDate: Date().addingTimeInterval(-7200),
                fileSize: 500000000,
                isSystemApp: false,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: [],
                urlSchemes: ["steam"],
                minimumSystemVersion: "10.15",
                architecture: ["x86_64"],
                codeSigningInfo: CodeSigningInfo(
                    isSigned: true,
                    signingIdentity: "Developer ID Application: Valve Corporation",
                    teamIdentifier: "ValveCorp",
                    certificateAuthority: ["Developer ID Certification Authority"],
                    timestamp: Date(),
                    isAdHocSigned: false,
                    isHardenedRuntime: false,
                    entitlements: nil
                ),
                appStoreInfo: AppStoreInfo(
                    isAppStoreApp: false,
                    appStoreVersion: nil,
                    purchaseDate: nil,
                    originalPurchaseDate: nil,
                    isPurchased: false,
                    isFree: true
                ),
                category: "games",
                developer: "Valve Corporation",
                copyright: "Copyright 2023 Valve Corporation",
                description: "Digital game distribution platform"
            ),
            AppInfo(
                name: "Norton Security",
                bundleIdentifier: "com.norton.antivirus",
                version: "22.25.0.1",
                buildNumber: "22.25.0.1",
                bundlePath: "/Applications/Norton Security.app",
                executablePath: "/Applications/Norton Security.app/Contents/MacOS/Norton Security",
                isRunning: true,
                launchDate: Date().addingTimeInterval(-1800),
                installDate: Date().addingTimeInterval(-1209600),
                lastOpenedDate: Date().addingTimeInterval(-900),
                fileSize: 800000000,
                isSystemApp: false,
                isLaunchAgent: true,
                isLaunchDaemon: true,
                isBackgroundAgent: true,
                supportedFileTypes: [],
                urlSchemes: ["norton"],
                minimumSystemVersion: "11.0",
                architecture: ["x86_64", "arm64"],
                codeSigningInfo: CodeSigningInfo(
                    isSigned: true,
                    signingIdentity: "Developer ID Application: NortonLifeLock Inc.",
                    teamIdentifier: "NortonLifeLock",
                    certificateAuthority: ["Developer ID Certification Authority"],
                    timestamp: Date(),
                    isAdHocSigned: false,
                    isHardenedRuntime: true,
                    entitlements: [
                        "com.apple.security.cs.allow-jit": "true",
                        "com.apple.security.cs.allow-unsigned-executable-memory": "true"
                    ]
                ),
                appStoreInfo: AppStoreInfo(
                    isAppStoreApp: false,
                    appStoreVersion: nil,
                    purchaseDate: nil,
                    originalPurchaseDate: nil,
                    isPurchased: true,
                    isFree: false
                ),
                category: "security",
                developer: "NortonLifeLock Inc.",
                copyright: "Copyright 2023 NortonLifeLock Inc.",
                description: "Comprehensive security and antivirus protection"
            )
        ]
    }
}
