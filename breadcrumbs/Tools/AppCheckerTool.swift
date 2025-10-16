//
//  AppCheckerTool.swift
//  breadcrumbs
//
//  Comprehensive app information checker using native macOS APIs
//

import AppKit
import Foundation

// MARK: - AppCheckerInput

/// Input model for app checker queries
struct AppCheckerInput: ToolInput, Codable {
    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case bundleIdentifier = "bundle_identifier"
        case category
        case includeSystemApps = "include_system_apps"
        case runningAppsOnly = "running_apps_only"
        case maxResults = "max_results"
    }

    /// Specific app name or bundle identifier to search for (optional)
    let appName: String?

    /// Bundle identifier to search for (optional)
    let bundleIdentifier: String?

    /// Filter by app category (e.g., "games", "utilities", "productivity")
    let category: String?

    /// Whether to include system apps in results
    let includeSystemApps: Bool?

    /// Whether to include running apps only
    let runningAppsOnly: Bool?

    /// Maximum number of results to return (default: 100)
    let maxResults: Int?

    func toDictionary() -> [String: Any] {
        guard
            let data = try? JSONEncoder().encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }

        return dict
    }
}

// MARK: - AppInfo

/// Detailed app information structure
struct AppInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case bundleIdentifier = "bundle_identifier"
        case version
        case buildNumber = "build_number"
        case bundlePath = "bundle_path"
        case executablePath = "executable_path"
        case isRunning = "is_running"
        case launchDate = "launch_date"
        case installDate = "install_date"
        case lastOpenedDate = "last_opened_date"
        case fileSize = "file_size"
        case isSystemApp = "is_system_app"
        case isLaunchAgent = "is_launch_agent"
        case isLaunchDaemon = "is_launch_daemon"
        case isBackgroundAgent = "is_background_agent"
        case supportedFileTypes = "supported_file_types"
        case urlSchemes = "url_schemes"
        case minimumSystemVersion = "minimum_system_version"
        case architecture
        case codeSigningInfo = "code_signing_info"
        case appStoreInfo = "app_store_info"
        case category
        case developer
        case copyright
        case description
    }

    let name: String
    let bundleIdentifier: String
    let version: String?
    let buildNumber: String?
    let bundlePath: String
    let executablePath: String?
    let isRunning: Bool
    let launchDate: Date?
    let installDate: Date?
    let lastOpenedDate: Date?
    let fileSize: Int64?
    let isSystemApp: Bool
    let isLaunchAgent: Bool
    let isLaunchDaemon: Bool
    let isBackgroundAgent: Bool
    let supportedFileTypes: [String]
    let urlSchemes: [String]
    let minimumSystemVersion: String?
    let architecture: [String]
    let codeSigningInfo: CodeSigningInfo?
    let appStoreInfo: AppStoreInfo?
    let category: String?
    let developer: String?
    let copyright: String?
    let description: String?
}

// MARK: - CodeSigningInfo

/// Code signing information
struct CodeSigningInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case isSigned = "is_signed"
        case signingIdentity = "signing_identity"
        case teamIdentifier = "team_identifier"
        case certificateAuthority = "certificate_authority"
        case timestamp
        case isAdHocSigned = "is_ad_hoc_signed"
        case isHardenedRuntime = "is_hardened_runtime"
        case entitlements
    }

    let isSigned: Bool
    let signingIdentity: String?
    let teamIdentifier: String?
    let certificateAuthority: [String]?
    let timestamp: Date?
    let isAdHocSigned: Bool
    let isHardenedRuntime: Bool
    let entitlements: [String: String]?
}

// MARK: - AppStoreInfo

/// App Store information
struct AppStoreInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case isAppStoreApp = "is_app_store_app"
        case appStoreVersion = "app_store_version"
        case purchaseDate = "purchase_date"
        case originalPurchaseDate = "original_purchase_date"
        case isPurchased = "is_purchased"
        case isFree = "is_free"
    }

    let isAppStoreApp: Bool
    let appStoreVersion: String?
    let purchaseDate: Date?
    let originalPurchaseDate: Date?
    let isPurchased: Bool
    let isFree: Bool
}

// MARK: - AppCheckerOutput

/// Output model for app checker results
struct AppCheckerOutput: ToolOutput {
    // MARK: Internal

    let query: String
    let totalAppsFound: Int
    let apps: [AppInfo]
    let searchCriteria: AppCheckerInput
    let timestamp: Date
    let systemInfo: SystemInfo

    func toFormattedString() -> String {
        var result = "App Checker Results:\n"
        result += "Query: \(query)\n"
        result += "Total Apps Found: \(totalAppsFound)\n"
        result += "Search Criteria: \(formatSearchCriteria())\n\n"

        if apps.isEmpty {
            result += "No apps found matching the criteria.\n"
        } else {
            // Use concise format if listing many apps (>20)
            let useCompactFormat = apps.count > 20

            result += "Apps Found:\n"
            result += String(repeating: "=", count: 50) + "\n"

            if useCompactFormat {
                // Compact format: one line per app
                result += "\n(Showing \(apps.count) apps in compact format)\n\n"
                for (index, app) in apps.enumerated() {
                    let runningIndicator = app.isRunning ? " [RUNNING]" : ""
                    let categoryInfo = app.category.map { " (\($0))" } ?? ""
                    result += "\(index + 1). \(app.name) - v\(app.version ?? "?") - \(app.bundleIdentifier)\(categoryInfo)\(runningIndicator)\n"
                }
            } else {
                // Detailed format for fewer apps
                for (index, app) in apps.enumerated() {
                    result += "\n\(index + 1). \(app.name)\n"
                    result += "   Bundle ID: \(app.bundleIdentifier)\n"
                    result += "   Version: \(app.version ?? "Unknown")\n"
                    result += "   Path: \(app.bundlePath)\n"
                    result += "   Running: \(app.isRunning ? "Yes" : "No")\n"

                    if let launchDate = app.launchDate {
                        result += "   Launch Date: \(formatDate(launchDate))\n"
                    }

                    if let installDate = app.installDate {
                        result += "   Install Date: \(formatDate(installDate))\n"
                    }

                    if let lastOpened = app.lastOpenedDate {
                        result += "   Last Opened: \(formatDate(lastOpened))\n"
                    }

                    if app.isSystemApp {
                        result += "   Type: System App\n"
                    }

                    if app.isLaunchAgent {
                        result += "   Launch Agent: Yes\n"
                    }

                    if app.isLaunchDaemon {
                        result += "   Launch Daemon: Yes\n"
                    }

                    if app.isBackgroundAgent {
                        result += "   Background Agent: Yes\n"
                    }

                    if let codeSigning = app.codeSigningInfo {
                        result += "   Code Signed: \(codeSigning.isSigned ? "Yes" : "No")\n"
                        if let identity = codeSigning.signingIdentity {
                            result += "   Signing Identity: \(identity)\n"
                        }
                    }

                    if let appStore = app.appStoreInfo, appStore.isAppStoreApp {
                        result += "   App Store: Yes\n"
                    }

                    if let category = app.category {
                        result += "   Category: \(category)\n"
                    }

                    if let developer = app.developer {
                        result += "   Developer: \(developer)\n"
                    }
                }
            }
        }

        result += "\n" + String(repeating: "=", count: 50) + "\n"
        result += "System Info: \(systemInfo.osVersion) (\(systemInfo.architecture))\n"
        result += "Checked at: \(formatDate(timestamp))"

        return result
    }

    // MARK: Private

    private func formatSearchCriteria() -> String {
        var criteria = [String]()

        if let appName = searchCriteria.appName {
            criteria.append("name: \(appName)")
        }
        if let bundleID = searchCriteria.bundleIdentifier {
            criteria.append("bundle_id: \(bundleID)")
        }
        if let category = searchCriteria.category {
            criteria.append("category: \(category)")
        }
        if searchCriteria.includeSystemApps == true {
            criteria.append("include_system_apps: true")
        }
        if searchCriteria.runningAppsOnly == true {
            criteria.append("running_only: true")
        }

        return criteria.isEmpty ? "all apps" : criteria.joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - SystemInfo

/// System information
struct SystemInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case osVersion = "os_version"
        case architecture
        case hostName = "host_name"
        case userName = "user_name"
    }

    let osVersion: String
    let architecture: String
    let hostName: String
    let userName: String
}

// MARK: - AppCheckerTool

/// Comprehensive tool for checking installed applications and their details
struct AppCheckerTool: AITool {
    // MARK: Internal

    let name = "app_checker"

    let description = """
    Comprehensive tool for checking installed applications on macOS. \
    Use this tool when users ask about installed apps, want to find specific applications, \
    check app versions, verify installations, or get detailed information about applications. \
    This tool can help answer questions like "Is Norton installed?", "What games do I have?", \
    "What version of Chrome is installed?", "Show me all my productivity apps", \
    "What apps are currently running?", or "Find apps by developer". \
    The tool provides detailed information including bundle identifiers, versions, \
    installation dates, running status, code signing, and more. \
    \
    IMPORTANT: When no specific app name or filter is provided, this tool will return a comprehensive \
    list of ALL installed applications on the system (up to max_results limit). This gives you a complete \
    inventory of what's installed, which is very helpful for answering questions about available software. \
    For example, if a user asks "what apps do I have?" or "what's installed?", call this with no parameters \
    to get the full list.
    """

    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "app_name": [
                    "type": "string",
                    "description": "Specific app name to search for (e.g., 'Chrome', 'Norton', 'Steam')",
                ],
                "bundle_identifier": [
                    "type": "string",
                    "description": "Bundle identifier to search for (e.g., 'com.google.Chrome', 'com.norton.antivirus')",
                ],
                "category": [
                    "type": "string",
                    "description": "Filter by app category (e.g., 'games', 'utilities', 'productivity', 'security')",
                ],
                "include_system_apps": [
                    "type": "boolean",
                    "description": "Whether to include system applications in results. Default: false",
                ],
                "running_apps_only": [
                    "type": "boolean",
                    "description": "Whether to return only currently running applications. Default: false",
                ],
                "max_results": [
                    "type": "integer",
                    "description": "Maximum number of results to return. Default: 100, Maximum: 500",
                    "minimum": 1,
                    "maximum": 500,
                ],
            ],
            "required": [],
        ])
    }

    @MainActor func execute(arguments: [String: Any]) async throws -> String {
        Logger.tools("AppCheckerTool.execute called with arguments: \(arguments)")

        // Parse input
        let input = parseInput(from: arguments)
        Logger
            .tools(
                "AppCheckerTool: parsed input - appName: \(input.appName ?? "nil"), bundleId: \(input.bundleIdentifier ?? "nil"), category: \(input.category ?? "nil")"
            )

        // Gather app information
        Logger.tools("AppCheckerTool: Starting app information gathering...")
        let apps = try await gatherAppInformation(input: input)
        Logger.tools("AppCheckerTool: Found \(apps.count) apps")

        // Get system information
        let systemInfo = getSystemInfo()

        // Create output
        let query = buildQueryString(from: input)
        let output = AppCheckerOutput(
            query: query,
            totalAppsFound: apps.count,
            apps: apps,
            searchCriteria: input,
            timestamp: Date(),
            systemInfo: systemInfo
        )

        // Return formatted string
        let result = output.toFormattedString()
        Logger.tools("AppCheckerTool: Returning result with \(apps.count) apps")
        return result
    }

    // MARK: - Private Methods

    func parseInput(from arguments: [String: Any]) -> AppCheckerInput {
        // If no filters are specified, increase default max results to show more apps
        let hasFilters = arguments["app_name"] != nil ||
                        arguments["bundle_identifier"] != nil ||
                        arguments["category"] != nil ||
                        arguments["running_apps_only"] as? Bool == true

        let defaultMaxResults = hasFilters ? 100 : 200  // Show more apps when listing all

        return AppCheckerInput(
            appName: arguments["app_name"] as? String,
            bundleIdentifier: arguments["bundle_identifier"] as? String,
            category: arguments["category"] as? String,
            includeSystemApps: arguments["include_system_apps"] as? Bool ?? false,
            runningAppsOnly: arguments["running_apps_only"] as? Bool ?? false,
            maxResults: arguments["max_results"] as? Int ?? defaultMaxResults
        )
    }

    func buildQueryString(from input: AppCheckerInput) -> String {
        var parts = [String]()

        if let appName = input.appName {
            parts.append("name: \(appName)")
        }
        if let bundleID = input.bundleIdentifier {
            parts.append("bundle: \(bundleID)")
        }
        if let category = input.category {
            parts.append("category: \(category)")
        }
        if input.runningAppsOnly == true {
            parts.append("running only")
        }
        if input.includeSystemApps == true {
            parts.append("including system apps")
        }

        return parts.isEmpty ? "all applications" : parts.joined(separator: ", ")
    }

    func getSupportedFileTypes(from bundle: Bundle) -> [String] {
        guard let documentTypes = bundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]]
        else {
            return []
        }

        var fileTypes = [String]()
        for docType in documentTypes {
            if let extensions = docType["CFBundleTypeExtensions"] as? [String] {
                fileTypes.append(contentsOf: extensions)
            }
        }

        return fileTypes
    }

    func getURLSchemes(from bundle: Bundle) -> [String] {
        guard let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }

        var schemes = [String]()
        for urlType in urlTypes {
            if let urlSchemes = urlType["CFBundleURLSchemes"] as? [String] {
                schemes.append(contentsOf: urlSchemes)
            }
        }

        return schemes
    }

    func extractSigningIdentity(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Authority=") {
                let components = line.components(separatedBy: "=")
                if components.count > 1 {
                    return components[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }

    func extractTeamIdentifier(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("TeamIdentifier=") {
                let components = line.components(separatedBy: "=")
                if components.count > 1 {
                    return components[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }

    func getAppStoreInfo(from bundle: Bundle) -> AppStoreInfo? {
        // Check if it's an App Store app by looking for receipt
        let receiptPath = bundle.appStoreReceiptURL?.path
        let isAppStoreApp = receiptPath != nil

        if isAppStoreApp {
            return AppStoreInfo(
                isAppStoreApp: true,
                appStoreVersion: nil,
                purchaseDate: nil,
                originalPurchaseDate: nil,
                isPurchased: true,
                isFree: false
            )
        }

        return AppStoreInfo(
            isAppStoreApp: false,
            appStoreVersion: nil,
            purchaseDate: nil,
            originalPurchaseDate: nil,
            isPurchased: false,
            isFree: false
        )
    }

    func getAppCategory(from bundle: Bundle, name: String) -> String? {
        // Try to determine category from bundle info or name patterns
        if let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String {
            return category
        }

        // Fallback to name-based categorization
        let lowercasedName = name.lowercased()

        if lowercasedName.contains("game") || lowercasedName.contains("steam") || lowercasedName.contains("epic") {
            return "games"
        } else if
            lowercasedName.contains("browser") || lowercasedName.contains("chrome") || lowercasedName
                .contains("firefox") || lowercasedName.contains("safari")
        {
            return "web_browsers"
        } else if
            lowercasedName.contains("security") || lowercasedName.contains("antivirus") || lowercasedName
                .contains("norton") || lowercasedName.contains("malware")
        {
            return "security"
        } else if
            lowercasedName.contains("office") || lowercasedName.contains("word") || lowercasedName
                .contains("excel") || lowercasedName.contains("powerpoint")
        {
            return "productivity"
        } else if
            lowercasedName.contains("media") || lowercasedName.contains("video") || lowercasedName
                .contains("audio") || lowercasedName.contains("music")
        {
            return "media"
        } else if
            lowercasedName.contains("development") || lowercasedName.contains("xcode") || lowercasedName
                .contains("code") || lowercasedName.contains("programming")
        {
            return "development"
        }

        return nil
    }

    func filterApps(_ apps: [AppInfo], with input: AppCheckerInput) -> [AppInfo] {
        return apps.filter { app in
            // Filter by app name
            if let appName = input.appName {
                if !app.name.localizedCaseInsensitiveContains(appName) {
                    return false
                }
            }

            // Filter by bundle identifier
            if let bundleID = input.bundleIdentifier {
                if !app.bundleIdentifier.localizedCaseInsensitiveContains(bundleID) {
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
            if !(input.includeSystemApps ?? false), app.isSystemApp {
                return false
            }

            // Filter by running apps
            if input.runningAppsOnly ?? false, !app.isRunning {
                return false
            }

            return true
        }
    }

    func getSystemInfo() -> SystemInfo {
        let processInfo = ProcessInfo.processInfo
        let hostName = processInfo.hostName
        let userName = NSUserName()

        let osVersion = processInfo.operatingSystemVersionString
        let architecture = "arm64" // Simplified for now

        return SystemInfo(
            osVersion: osVersion,
            architecture: architecture,
            hostName: hostName,
            userName: userName
        )
    }

    // MARK: Private

    private func gatherAppInformation(input: AppCheckerInput) async throws -> [AppInfo] {
        var allApps = [AppInfo]()

        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        let runningAppInfos = await withTaskGroup(of: AppInfo?.self, returning: [AppInfo].self) { group in
            for app in runningApps {
                group.addTask {
                    await self.getAppInfo(from: app.bundleURL, isRunning: true, runningApp: app)
                }
            }

            var results = [AppInfo]()
            for await appInfo in group {
                if let appInfo = appInfo {
                    results.append(appInfo)
                }
            }
            return results
        }
        allApps.append(contentsOf: runningAppInfos)

        // If not running apps only, get all installed apps
        if !(input.runningAppsOnly ?? false) {
            let installedApps = try await getAllInstalledApps(includeSystemApps: input.includeSystemApps ?? false)
            let installedAppInfos = await withTaskGroup(of: AppInfo?.self, returning: [AppInfo].self) { group in
                for appURL in installedApps {
                    // Skip if we already have this app from running apps
                    if allApps.contains(where: { $0.bundlePath == appURL.path }) {
                        continue
                    }

                    group.addTask {
                        await self.getAppInfo(from: appURL, isRunning: false, runningApp: nil)
                    }
                }

                var results = [AppInfo]()
                for await appInfo in group {
                    if let appInfo = appInfo {
                        results.append(appInfo)
                    }
                }
                return results
            }
            allApps.append(contentsOf: installedAppInfos)
        }

        // Filter results based on criteria
        let filteredApps = filterApps(allApps, with: input)

        // Sort and limit results
        let sortedApps = filteredApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let maxResults = min(input.maxResults ?? 100, 500)

        return Array(sortedApps.prefix(maxResults))
    }

    private func getAllInstalledApps(includeSystemApps: Bool) async throws -> [URL] {
        return try await Task.detached {
            var appURLs = [URL]()

            // Standard application directories
            let applicationDirectories = [
                FileManager.SearchPathDirectory.applicationDirectory,
                FileManager.SearchPathDirectory.allApplicationsDirectory,
            ]

            for directory in applicationDirectories {
                if let url = FileManager.default.urls(for: directory, in: .localDomainMask).first {
                    let apps = try await self.getAppsFromDirectory(url: url, includeSystemApps: includeSystemApps)
                    appURLs.append(contentsOf: apps)
                }
            }

            // User's Applications folder
            if let userAppsURL = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
                let userApps = try await self.getAppsFromDirectory(
                    url: userAppsURL,
                    includeSystemApps: includeSystemApps
                )
                appURLs.append(contentsOf: userApps)
            }

            return appURLs
        }
        .value
    }

    private func getAppsFromDirectory(url: URL, includeSystemApps: Bool) async throws -> [URL] {
        return try await Task.detached {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )

            var appURLs = [URL]()

            while let fileURL = enumerator?.nextObject() as? URL {
                // Check if it's an application bundle
                let resourceValues = try fileURL.resourceValues(forKeys: [.isApplicationKey])

                if resourceValues.isApplication == true {
                    // Simple system app detection based on path
                    let isSystemApp = fileURL.path.contains("/System/") || fileURL.path.contains("/Library/")

                    if includeSystemApps || !isSystemApp {
                        appURLs.append(fileURL)
                    }
                }
            }

            return appURLs
        }
        .value
    }

    private func getAppInfo(
        from bundleURL: URL?,
        isRunning: Bool,
        runningApp: NSRunningApplication?
    ) async
        -> AppInfo?
    {
        guard let bundleURL = bundleURL else {
            return nil
        }

        let bundle = Bundle(url: bundleURL)
        guard let bundle = bundle else {
            return nil
        }

        // Basic bundle information
        let name = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? bundleURL
            .lastPathComponent
            .replacingOccurrences(
                of: ".app",
                with: ""
            )
        let bundleIdentifier = bundle.bundleIdentifier ?? "unknown"
        let version = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let executablePath = bundle.executablePath
        let minimumSystemVersion = bundle.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String
        let developer = bundle.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        let copyright = bundle.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        let description = bundle.object(forInfoDictionaryKey: kCFBundleInfoDictionaryVersionKey as String) as? String

        // File system information
        let fileSize = try? Int64(bundleURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
        let installDate = try? bundleURL.resourceValues(forKeys: [.creationDateKey]).creationDate
        let lastOpenedDate = try? bundleURL.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate

        // Running app information
        let launchDate = runningApp?.launchDate

        // System app detection
        let isSystemApp = bundleURL.path.contains("/System/") || bundleURL.path.contains("/Library/")

        // Launch agent/daemon detection
        let (isLaunchAgent, isLaunchDaemon, isBackgroundAgent) = await checkLaunchServices(for: bundleIdentifier)

        // Supported file types and URL schemes
        let supportedFileTypes = getSupportedFileTypes(from: bundle)
        let urlSchemes = getURLSchemes(from: bundle)

        // Architecture information
        let architecture = await getArchitecture(from: bundle)

        // Code signing information
        let codeSigningInfo = await getCodeSigningInfo(for: bundleURL)

        // App Store information
        let appStoreInfo = getAppStoreInfo(from: bundle)

        // Category detection
        let category = getAppCategory(from: bundle, name: name)

        return AppInfo(
            name: name,
            bundleIdentifier: bundleIdentifier,
            version: version,
            buildNumber: buildNumber,
            bundlePath: bundleURL.path,
            executablePath: executablePath,
            isRunning: isRunning,
            launchDate: launchDate,
            installDate: installDate,
            lastOpenedDate: lastOpenedDate,
            fileSize: fileSize,
            isSystemApp: isSystemApp,
            isLaunchAgent: isLaunchAgent,
            isLaunchDaemon: isLaunchDaemon,
            isBackgroundAgent: isBackgroundAgent,
            supportedFileTypes: supportedFileTypes,
            urlSchemes: urlSchemes,
            minimumSystemVersion: minimumSystemVersion,
            architecture: architecture,
            codeSigningInfo: codeSigningInfo,
            appStoreInfo: appStoreInfo,
            category: category,
            developer: developer,
            copyright: copyright,
            description: description
        )
    }

    private func checkLaunchServices(for bundleIdentifier: String) async -> (Bool, Bool, Bool) {
        return await Task.detached {
            // Check for launch agents and daemons
            let launchAgentPaths = [
                "~/Library/LaunchAgents/",
                "/Library/LaunchAgents/",
                "/System/Library/LaunchAgents/",
            ]

            let launchDaemonPaths = [
                "/Library/LaunchDaemons/",
                "/System/Library/LaunchDaemons/",
            ]

            var isLaunchAgent = false
            var isLaunchDaemon = false
            var isBackgroundAgent = false

            for path in launchAgentPaths {
                let expandedPath = NSString(string: path).expandingTildeInPath
                if let plistFiles = try? FileManager.default.contentsOfDirectory(atPath: expandedPath) {
                    for plistFile in plistFiles {
                        if plistFile.contains(bundleIdentifier) {
                            isLaunchAgent = true
                            break
                        }
                    }
                }
            }

            for path in launchDaemonPaths {
                if let plistFiles = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    for plistFile in plistFiles {
                        if plistFile.contains(bundleIdentifier) {
                            isLaunchDaemon = true
                            break
                        }
                    }
                }
            }

            // Check for background agents (simplified detection)
            isBackgroundAgent = isLaunchAgent || isLaunchDaemon

            return (isLaunchAgent, isLaunchDaemon, isBackgroundAgent)
        }
        .value
    }

    private func getArchitecture(from bundle: Bundle) async -> [String] {
        guard let executablePath = bundle.executablePath else {
            return []
        }

        return await Task.detached {
            // Use file command to determine architecture
            let task = Process()
            task.launchPath = "/usr/bin/file"
            task.arguments = [executablePath]

            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    var architectures = [String]()
                    if output.contains("x86_64") {
                        architectures.append("x86_64")
                    }
                    if output.contains("arm64") {
                        architectures.append("arm64")
                    }
                    if output.contains("universal") {
                        architectures.append("universal")
                    }
                    return architectures
                }
            } catch {
                Logger.tools("AppCheckerTool: Error getting architecture: \(error)")
            }

            return []
        }
        .value
    }

    private func getCodeSigningInfo(for bundleURL: URL) async -> CodeSigningInfo? {
        let bundlePath = bundleURL.path

        return await Task.detached {
            // Use codesign command to get signing information
            let task = Process()
            task.launchPath = "/usr/bin/codesign"
            task.arguments = ["-dv", "--verbose=4", bundlePath]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let isSigned = !output.contains("not signed")
                    let signingIdentity = self.extractSigningIdentity(from: output)
                    let teamIdentifier = self.extractTeamIdentifier(from: output)
                    let isAdHocSigned = output.contains("ad-hoc")
                    let isHardenedRuntime = output.contains("runtime")

                    return CodeSigningInfo(
                        isSigned: isSigned,
                        signingIdentity: signingIdentity,
                        teamIdentifier: teamIdentifier,
                        certificateAuthority: nil,
                        timestamp: nil,
                        isAdHocSigned: isAdHocSigned,
                        isHardenedRuntime: isHardenedRuntime,
                        entitlements: nil
                    )
                }
            } catch {
                Logger.tools("AppCheckerTool: Error getting code signing info: \(error)")
            }

            return nil
        }
        .value
    }
}
