//
//  AppCheckerToolTests.swift
//  breadcrumbsTests
//
//  Comprehensive tests for AppCheckerTool
//

import AppKit
@testable import breadcrumbs
import XCTest

// MARK: - AppCheckerToolTests

@MainActor
final class AppCheckerToolTests: XCTestCase {
    // MARK: Internal

    var tool: AppCheckerTool!
    var mockFileManager: MockFileManager!
    var mockWorkspace: MockWorkspace!

    override func setUp() {
        super.setUp()
        tool = AppCheckerTool()
        mockFileManager = MockFileManager()
        mockWorkspace = MockWorkspace()
    }

    override func tearDown() {
        tool = nil
        mockFileManager = nil
        mockWorkspace = nil
        super.tearDown()
    }

    // MARK: - Tool Protocol Tests

    func testToolName() {
        XCTAssertEqual(tool.name, "app_checker")
    }

    func testToolDescription() {
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertTrue(tool.description.contains("applications"))
        XCTAssertTrue(tool.description.contains("bundle"))
    }

    func testParametersSchema() throws {
        let schema = tool.parametersSchema.jsonSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = try XCTUnwrap(schema["properties"] as? [String: Any])

        XCTAssertNotNil(properties["app_name"])
        XCTAssertNotNil(properties["bundle_identifier"])
        XCTAssertNotNil(properties["category"])
        XCTAssertNotNil(properties["include_system_apps"])
        XCTAssertNotNil(properties["running_apps_only"])
        XCTAssertNotNil(properties["max_results"])

        let required = schema["required"] as? [String] ?? []
        XCTAssertTrue(required.isEmpty, "No parameters should be required")
    }

    // MARK: - Input Parsing Tests

    func testParseInputWithAllParameters() {
        let arguments: [String: Any] = [
            "app_name": "Chrome",
            "bundle_identifier": "com.google.Chrome",
            "category": "browsers",
            "include_system_apps": true,
            "running_apps_only": false,
            "max_results": 50,
        ]

        let input = tool.parseInput(from: arguments)

        XCTAssertEqual(input.appName, "Chrome")
        XCTAssertEqual(input.bundleIdentifier, "com.google.Chrome")
        XCTAssertEqual(input.category, "browsers")
        XCTAssertTrue(input.includeSystemApps ?? false)
        XCTAssertFalse(input.runningAppsOnly ?? true)
        XCTAssertEqual(input.maxResults, 50)
    }

    func testParseInputWithDefaults() {
        let arguments = [String: Any]()

        let input = tool.parseInput(from: arguments)

        XCTAssertNil(input.appName)
        XCTAssertNil(input.bundleIdentifier)
        XCTAssertNil(input.category)
        XCTAssertFalse(input.includeSystemApps ?? true)
        XCTAssertFalse(input.runningAppsOnly ?? true)
        XCTAssertEqual(input.maxResults, 100)
    }

    func testParseInputWithPartialParameters() {
        let arguments: [String: Any] = [
            "app_name": "Safari",
            "running_apps_only": true,
        ]

        let input = tool.parseInput(from: arguments)

        XCTAssertEqual(input.appName, "Safari")
        XCTAssertNil(input.bundleIdentifier)
        XCTAssertNil(input.category)
        XCTAssertFalse(input.includeSystemApps ?? true)
        XCTAssertTrue(input.runningAppsOnly ?? false)
        XCTAssertEqual(input.maxResults, 100)
    }

    // MARK: - Query String Building Tests

    func testBuildQueryStringWithAllParameters() {
        let input = AppCheckerInput(
            appName: "Chrome",
            bundleIdentifier: "com.google.Chrome",
            category: "browsers",
            includeSystemApps: true,
            runningAppsOnly: false,
            maxResults: 50
        )

        let query = tool.buildQueryString(from: input)

        XCTAssertTrue(query.contains("name: Chrome"))
        XCTAssertTrue(query.contains("bundle: com.google.Chrome"))
        XCTAssertTrue(query.contains("category: browsers"))
        XCTAssertTrue(query.contains("including system apps"))
        XCTAssertFalse(query.contains("running only"))
    }

    func testBuildQueryStringWithNoParameters() {
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: nil,
            category: nil,
            includeSystemApps: false,
            runningAppsOnly: false,
            maxResults: 100
        )

        let query = tool.buildQueryString(from: input)

        XCTAssertEqual(query, "all applications")
    }

    func testBuildQueryStringWithRunningAppsOnly() {
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: nil,
            category: nil,
            includeSystemApps: false,
            runningAppsOnly: true,
            maxResults: 100
        )

        let query = tool.buildQueryString(from: input)

        XCTAssertEqual(query, "running only")
    }

    // MARK: - App Filtering Tests

    func testFilterAppsByName() {
        let apps = createMockApps()
        let input = AppCheckerInput(
            appName: "Chrome",
            bundleIdentifier: nil,
            category: nil,
            includeSystemApps: true,
            runningAppsOnly: false,
            maxResults: 100
        )

        let filtered = tool.filterApps(apps, with: input)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Google Chrome")
    }

    func testFilterAppsByBundleIdentifier() {
        let apps = createMockApps()
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: "com.apple.Safari",
            category: nil,
            includeSystemApps: true,
            runningAppsOnly: false,
            maxResults: 100
        )

        let filtered = tool.filterApps(apps, with: input)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.bundleIdentifier, "com.apple.Safari")
    }

    func testFilterAppsByCategory() {
        let apps = createMockApps()
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: nil,
            category: "games",
            includeSystemApps: true,
            runningAppsOnly: false,
            maxResults: 100
        )

        let filtered = tool.filterApps(apps, with: input)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.category, "games")
    }

    func testFilterAppsExcludeSystemApps() {
        let apps = createMockApps()
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: nil,
            category: nil,
            includeSystemApps: false,
            runningAppsOnly: false,
            maxResults: 100
        )

        let filtered = tool.filterApps(apps, with: input)

        XCTAssertEqual(filtered.count, 2) // Only non-system apps
        XCTAssertTrue(filtered.allSatisfy { !$0.isSystemApp })
    }

    func testFilterAppsRunningOnly() {
        let apps = createMockApps()
        let input = AppCheckerInput(
            appName: nil,
            bundleIdentifier: nil,
            category: nil,
            includeSystemApps: true,
            runningAppsOnly: true,
            maxResults: 100
        )

        let filtered = tool.filterApps(apps, with: input)

        XCTAssertEqual(filtered.count, 1) // Only running app
        XCTAssertTrue(filtered.allSatisfy { $0.isRunning })
    }

    // MARK: - System Info Tests

    func testGetSystemInfo() {
        let systemInfo = tool.getSystemInfo()

        XCTAssertFalse(systemInfo.osVersion.isEmpty)
        XCTAssertFalse(systemInfo.architecture.isEmpty)
        XCTAssertFalse(systemInfo.hostName.isEmpty)
        XCTAssertFalse(systemInfo.userName.isEmpty)
    }

    // MARK: - App Info Extraction Tests

    func testExtractSigningIdentity() {
        let output = """
        Authority=Developer ID Application: Google LLC (EQHXZ8M8AV)
        TeamIdentifier=EQHXZ8M8AV
        """

        let identity = tool.extractSigningIdentity(from: output)

        XCTAssertEqual(identity, "Developer ID Application: Google LLC (EQHXZ8M8AV)")
    }

    func testExtractTeamIdentifier() {
        let output = """
        Authority=Developer ID Application: Google LLC (EQHXZ8M8AV)
        TeamIdentifier=EQHXZ8M8AV
        """

        let teamID = tool.extractTeamIdentifier(from: output)

        XCTAssertEqual(teamID, "EQHXZ8M8AV")
    }

    func testExtractSigningIdentityNotFound() {
        let output = "No signing information found"

        let identity = tool.extractSigningIdentity(from: output)

        XCTAssertNil(identity)
    }

    // MARK: - Category Detection Tests

    func testGetAppCategoryFromBundle() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = ["LSApplicationCategoryType": "public.app-category.games"]

        let category = tool.getAppCategory(from: mockBundle, name: "Test Game")

        XCTAssertEqual(category, "public.app-category.games")
    }

    func testGetAppCategoryFromName() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [:]

        let gameCategory = tool.getAppCategory(from: mockBundle, name: "Steam Game")
        let browserCategory = tool.getAppCategory(from: mockBundle, name: "Chrome Browser")
        let securityCategory = tool.getAppCategory(from: mockBundle, name: "Norton Antivirus")

        XCTAssertEqual(gameCategory, "games")
        XCTAssertEqual(browserCategory, "web_browsers")
        XCTAssertEqual(securityCategory, "security")
    }

    func testGetAppCategoryNotFound() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [:]

        let category = tool.getAppCategory(from: mockBundle, name: "Unknown App")

        XCTAssertNil(category)
    }

    // MARK: - URL Schemes Tests

    func testGetURLSchemes() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [
            "CFBundleURLTypes": [
                [
                    "CFBundleURLSchemes": ["https", "http"],
                ],
                [
                    "CFBundleURLSchemes": ["myapp"],
                ],
            ],
        ]

        let schemes = tool.getURLSchemes(from: mockBundle)

        XCTAssertEqual(schemes.count, 3)
        XCTAssertTrue(schemes.contains("https"))
        XCTAssertTrue(schemes.contains("http"))
        XCTAssertTrue(schemes.contains("myapp"))
    }

    func testGetURLSchemesEmpty() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [:]

        let schemes = tool.getURLSchemes(from: mockBundle)

        XCTAssertTrue(schemes.isEmpty)
    }

    // MARK: - Supported File Types Tests

    func testGetSupportedFileTypes() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [
            "CFBundleDocumentTypes": [
                [
                    "CFBundleTypeExtensions": ["txt", "md"],
                ],
                [
                    "CFBundleTypeExtensions": ["pdf"],
                ],
            ],
        ]

        let fileTypes = tool.getSupportedFileTypes(from: mockBundle)

        XCTAssertEqual(fileTypes.count, 3)
        XCTAssertTrue(fileTypes.contains("txt"))
        XCTAssertTrue(fileTypes.contains("md"))
        XCTAssertTrue(fileTypes.contains("pdf"))
    }

    func testGetSupportedFileTypesEmpty() {
        let mockBundle = MockBundle()
        mockBundle.mockInfoDictionary = [:]

        let fileTypes = tool.getSupportedFileTypes(from: mockBundle)

        XCTAssertTrue(fileTypes.isEmpty)
    }

    // MARK: - App Store Info Tests

    func testGetAppStoreInfoWithReceipt() {
        let mockBundle = MockBundle()
        mockBundle.mockAppStoreReceiptURL = URL(fileURLWithPath: "/path/to/receipt")

        let appStoreInfo = tool.getAppStoreInfo(from: mockBundle)

        XCTAssertNotNil(appStoreInfo)
        XCTAssertTrue(appStoreInfo?.isAppStoreApp == true)
        XCTAssertTrue(appStoreInfo?.isPurchased == true)
    }

    func testGetAppStoreInfoWithoutReceipt() {
        let mockBundle = MockBundle()
        mockBundle.mockAppStoreReceiptURL = nil

        let appStoreInfo = tool.getAppStoreInfo(from: mockBundle)

        XCTAssertNotNil(appStoreInfo)
        XCTAssertFalse(appStoreInfo?.isAppStoreApp == true)
        XCTAssertFalse(appStoreInfo?.isPurchased == true)
    }

    // MARK: - Error Handling Tests

    func testExecuteWithInvalidArguments() async throws {
        let arguments: [String: Any] = [
            "max_results": "invalid", // This should be handled gracefully, not throw an error
        ]

        // The tool should handle invalid arguments gracefully by using defaults
        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("App Checker Results:"))
        // The tool should use the default maxResults value (100) when invalid value is provided
    }

    func testExecuteWithEmptyArguments() async {
        let arguments = [String: Any]()

        do {
            let result = try await tool.execute(arguments: arguments)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("App Checker Results"))
        } catch {
            XCTFail("Should not throw error with empty arguments: \(error)")
        }
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createMockApps() -> [AppInfo] {
        return [
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
                fileSize: 200_000_000,
                isSystemApp: false,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: ["html", "htm"],
                urlSchemes: ["https", "http"],
                minimumSystemVersion: "10.15",
                architecture: ["x86_64", "arm64"],
                codeSigningInfo: nil,
                appStoreInfo: nil,
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
                installDate: Date().addingTimeInterval(-2_592_000),
                lastOpenedDate: Date().addingTimeInterval(-3600),
                fileSize: 150_000_000,
                isSystemApp: true,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: ["html", "htm", "webarchive"],
                urlSchemes: ["https", "http"],
                minimumSystemVersion: "15.0",
                architecture: ["arm64"],
                codeSigningInfo: nil,
                appStoreInfo: nil,
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
                installDate: Date().addingTimeInterval(-604_800),
                lastOpenedDate: Date().addingTimeInterval(-7200),
                fileSize: 500_000_000,
                isSystemApp: false,
                isLaunchAgent: false,
                isLaunchDaemon: false,
                isBackgroundAgent: false,
                supportedFileTypes: [],
                urlSchemes: ["steam"],
                minimumSystemVersion: "10.15",
                architecture: ["x86_64"],
                codeSigningInfo: nil,
                appStoreInfo: nil,
                category: "games",
                developer: "Valve Corporation",
                copyright: "Copyright 2023 Valve Corporation",
                description: "Digital game distribution platform"
            ),
        ]
    }
}

// MARK: - MockFileManager

final class MockFileManager: FileManager {
    var mockContents: [String: [String]] = [:]
    var mockResourceValues: [String: URLResourceValues] = [:]

    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        return mockContents[path] ?? []
    }

    func resourceValues(forKeys keys: Set<URLResourceKey>, from url: URL) throws -> URLResourceValues {
        return mockResourceValues[url.path] ?? URLResourceValues()
    }
}

// MARK: - MockWorkspace

final class MockWorkspace: NSWorkspace {
    override var runningApplications: [NSRunningApplication] {
        return mockRunningApplications
    }

    var mockRunningApplications: [NSRunningApplication] = []
}

// MARK: - MockBundle

final class MockBundle: Bundle, @unchecked Sendable {
    override var infoDictionary: [String: Any]? {
        return mockInfoDictionary
    }

    override var bundleIdentifier: String? {
        return mockBundleIdentifier
    }

    override var executablePath: String? {
        return mockExecutablePath
    }

    override var appStoreReceiptURL: URL? {
        return mockAppStoreReceiptURL
    }

    var mockInfoDictionary: [String: Any] = [:]
    var mockBundleIdentifier: String?
    var mockExecutablePath: String?
    var mockAppStoreReceiptURL: URL?
}
