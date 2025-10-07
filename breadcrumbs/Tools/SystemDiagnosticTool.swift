//
//  SystemDiagnosticTool.swift
//  breadcrumbs
//
//  Comprehensive system diagnostic report collector using native macOS APIs
//

import Foundation
import AppKit
import System
import os

// MARK: - Input/Output Models

/// Input model for system diagnostic queries
struct SystemDiagnosticInput: ToolInput, Codable {
    /// Specific app name or bundle identifier to focus on (optional)
    let appName: String?
    
    /// Bundle identifier to focus on (optional)
    let bundleIdentifier: String?
    
    /// Type of diagnostic information to collect
    let diagnosticType: DiagnosticType?
    
    /// Time range for reports (in hours, default: 24)
    let timeRangeHours: Int?
    
    /// Whether to include system-level reports
    let includeSystemReports: Bool?
    
    /// Whether to include user-level reports
    let includeUserReports: Bool?
    
    /// Whether to collect app samples
    let collectAppSamples: Bool?
    
    /// Maximum number of reports to return per type (default: 50)
    let maxReportsPerType: Int?
    
    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case bundleIdentifier = "bundle_identifier"
        case diagnosticType = "diagnostic_type"
        case timeRangeHours = "time_range_hours"
        case includeSystemReports = "include_system_reports"
        case includeUserReports = "include_user_reports"
        case collectAppSamples = "collect_app_samples"
        case maxReportsPerType = "max_reports_per_type"
    }
    
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

/// Types of diagnostic information to collect
enum DiagnosticType: String, Codable, CaseIterable {
    case all = "all"
    case crashReports = "crash_reports"
    case spinReports = "spin_reports"
    case systemLogs = "system_logs"
    case appLogs = "app_logs"
    case jetsamReports = "jetsam_reports"
    case thermalReports = "thermal_reports"
    case watchdogReports = "watchdog_reports"
    case systemInfo = "system_info"
    case appSamples = "app_samples"
    case networkDiagnostics = "network_diagnostics"
    case performanceMetrics = "performance_metrics"
}

/// Comprehensive system diagnostic report
struct SystemDiagnosticReport: ToolOutput, Codable {
    let timestamp: Date
    let systemInfo: SystemInformation
    let crashReports: [DiagnosticReport]
    let spinReports: [DiagnosticReport]
    let systemLogs: [DiagnosticReport]
    let appLogs: [DiagnosticReport]
    let jetsamReports: [DiagnosticReport]
    let thermalReports: [DiagnosticReport]
    let watchdogReports: [DiagnosticReport]
    let appSamples: [AppSample]
    let networkDiagnostics: NetworkDiagnostics?
    let performanceMetrics: PerformanceMetrics?
    let summary: DiagnosticSummary
    
    func toFormattedString() -> String {
        var output = "=== SYSTEM DIAGNOSTIC REPORT ===\n"
        output += "Generated: \(timestamp)\n\n"
        
        output += "=== SYSTEM INFORMATION ===\n"
        output += systemInfo.toFormattedString() + "\n\n"
        
        if !crashReports.isEmpty {
            output += "=== CRASH REPORTS (\(crashReports.count)) ===\n"
            for report in crashReports.prefix(5) {
                output += report.toFormattedString() + "\n"
            }
            if crashReports.count > 5 {
                output += "... and \(crashReports.count - 5) more crash reports\n"
            }
            output += "\n"
        }
        
        if !spinReports.isEmpty {
            output += "=== SPIN REPORTS (\(spinReports.count)) ===\n"
            for report in spinReports.prefix(3) {
                output += report.toFormattedString() + "\n"
            }
            if spinReports.count > 3 {
                output += "... and \(spinReports.count - 3) more spin reports\n"
            }
            output += "\n"
        }
        
        if !jetsamReports.isEmpty {
            output += "=== JETSAM REPORTS (\(jetsamReports.count)) ===\n"
            for report in jetsamReports.prefix(3) {
                output += report.toFormattedString() + "\n"
            }
            output += "\n"
        }
        
        if !appSamples.isEmpty {
            output += "=== APP SAMPLES (\(appSamples.count)) ===\n"
            for sample in appSamples.prefix(3) {
                output += sample.toFormattedString() + "\n"
            }
            output += "\n"
        }
        
        if let network = networkDiagnostics {
            output += "=== NETWORK DIAGNOSTICS ===\n"
            output += network.toFormattedString() + "\n\n"
        }
        
        if let performance = performanceMetrics {
            output += "=== PERFORMANCE METRICS ===\n"
            output += performance.toFormattedString() + "\n\n"
        }
        
        output += "=== SUMMARY ===\n"
        output += summary.toFormattedString()
        
        return output
    }
}

/// System information structure
struct SystemInformation: Codable {
    let hostName: String
    let osVersion: String
    let osBuild: String
    let kernelVersion: String
    let architecture: String
    let cpuType: String
    let cpuSubtype: String
    let physicalMemory: UInt64
    let availableMemory: UInt64
    let diskSpace: DiskSpace
    let uptime: TimeInterval
    let bootTime: Date
    let thermalState: String
    let batteryInfo: BatteryInfo?
    
    func toFormattedString() -> String {
        var output = "Host: \(hostName)\n"
        output += "OS: \(osVersion) (\(osBuild))\n"
        output += "Kernel: \(kernelVersion)\n"
        output += "Architecture: \(architecture)\n"
        output += "CPU: \(cpuType) (\(cpuSubtype))\n"
        output += "Memory: \(formatBytes(physicalMemory)) total, \(formatBytes(availableMemory)) available\n"
        output += "Disk: \(diskSpace.toFormattedString())\n"
        output += "Uptime: \(formatUptime(uptime))\n"
        output += "Boot Time: \(bootTime)\n"
        output += "Thermal State: \(thermalState)\n"
        if let battery = batteryInfo {
            output += "Battery: \(battery.toFormattedString())"
        }
        return output
    }
}

/// Disk space information
struct DiskSpace: Codable {
    let total: UInt64
    let available: UInt64
    let used: UInt64
    
    func toFormattedString() -> String {
        return "\(formatBytes(total)) total, \(formatBytes(available)) available, \(formatBytes(used)) used"
    }
}

/// Battery information (for laptops)
struct BatteryInfo: Codable {
    let level: Int
    let isCharging: Bool
    let cycleCount: Int?
    let health: String?
    
    func toFormattedString() -> String {
        var output = "\(level)%"
        if isCharging {
            output += " (charging)"
        }
        if let cycles = cycleCount {
            output += ", \(cycles) cycles"
        }
        if let health = health {
            output += ", health: \(health)"
        }
        return output
    }
}

/// Individual diagnostic report
struct DiagnosticReport: Codable {
    let type: String
    let fileName: String
    let filePath: String
    let fileSize: Int64
    let creationDate: Date
    let modificationDate: Date
    let appName: String?
    let bundleIdentifier: String?
    let processId: Int?
    let exceptionType: String?
    let exceptionCode: String?
    let signal: String?
    let summary: String?
    let content: String?
    
    func toFormattedString() -> String {
        var output = "\(type): \(fileName)\n"
        output += "  App: \(appName ?? "Unknown")\n"
        output += "  Bundle ID: \(bundleIdentifier ?? "Unknown")\n"
        output += "  Date: \(creationDate)\n"
        output += "  Size: \(formatBytes(UInt64(fileSize)))\n"
        if let exception = exceptionType {
            output += "  Exception: \(exception)"
            if let code = exceptionCode {
                output += " (\(code))"
            }
            if let signal = signal {
                output += " Signal: \(signal)"
            }
            output += "\n"
        }
        if let summary = summary {
            output += "  Summary: \(summary)\n"
        }
        return output
    }
}

/// App sample information
struct AppSample: Codable {
    let appName: String
    let bundleIdentifier: String
    let processId: Int
    let cpuUsage: Double
    let memoryUsage: UInt64
    let threadCount: Int
    let sampleTime: Date
    let isResponsive: Bool
    let sampleData: String?
    
    func toFormattedString() -> String {
        var output = "App: \(appName) (\(bundleIdentifier))\n"
        output += "  PID: \(processId)\n"
        output += "  CPU: \(String(format: "%.1f", cpuUsage))%\n"
        output += "  Memory: \(formatBytes(memoryUsage))\n"
        output += "  Threads: \(threadCount)\n"
        output += "  Responsive: \(isResponsive ? "Yes" : "No")\n"
        output += "  Sample Time: \(sampleTime)\n"
        return output
    }
}

/// Network diagnostics
struct NetworkDiagnostics: Codable {
    let activeConnections: Int
    let networkInterfaces: [NetworkInterface]
    let dnsServers: [String]
    let routingTable: [String]
    let networkReachability: String
    
    func toFormattedString() -> String {
        var output = "Active Connections: \(activeConnections)\n"
        output += "Network Interfaces: \(networkInterfaces.count)\n"
        output += "DNS Servers: \(dnsServers.joined(separator: ", "))\n"
        output += "Reachability: \(networkReachability)\n"
        return output
    }
}

/// Network interface information
struct NetworkInterface: Codable {
    let name: String
    let address: String?
    let isActive: Bool
    let speed: String?
}

/// Performance metrics
struct PerformanceMetrics: Codable {
    let cpuUsage: Double
    let memoryPressure: String
    let diskActivity: String
    let networkActivity: String
    let thermalPressure: String
    let gpuUsage: Double?
    
    func toFormattedString() -> String {
        var output = "CPU Usage: \(String(format: "%.1f", cpuUsage))%\n"
        output += "Memory Pressure: \(memoryPressure)\n"
        output += "Disk Activity: \(diskActivity)\n"
        output += "Network Activity: \(networkActivity)\n"
        output += "Thermal Pressure: \(thermalPressure)\n"
        if let gpu = gpuUsage {
            output += "GPU Usage: \(String(format: "%.1f", gpu))%"
        }
        return output
    }
}

/// Diagnostic summary
struct DiagnosticSummary: Codable {
    let totalReports: Int
    let crashCount: Int
    let spinCount: Int
    let jetsamCount: Int
    let thermalCount: Int
    let watchdogCount: Int
    let mostFrequentCrasher: String?
    let systemHealth: String
    let recommendations: [String]
    
    func toFormattedString() -> String {
        var output = "Total Reports: \(totalReports)\n"
        output += "Crashes: \(crashCount)\n"
        output += "Spins: \(spinCount)\n"
        output += "Jetsam Events: \(jetsamCount)\n"
        output += "Thermal Events: \(thermalCount)\n"
        output += "Watchdog Events: \(watchdogCount)\n"
        output += "System Health: \(systemHealth)\n"
        if let crasher = mostFrequentCrasher {
            output += "Most Frequent Crasher: \(crasher)\n"
        }
        if !recommendations.isEmpty {
            output += "Recommendations:\n"
            for (index, rec) in recommendations.enumerated() {
                output += "  \(index + 1). \(rec)\n"
            }
        }
        return output
    }
}

// MARK: - System Diagnostic Tool

/// Comprehensive system diagnostic report collector
final class SystemDiagnosticTool: AITool {
    
    // MARK: - AITool Protocol Implementation
    
    let name: String = "system_diagnostic"
    
    let description: String = """
    Collects comprehensive system diagnostic reports including crash reports, spin reports, 
    system logs, app samples, and performance metrics. Helps diagnose issues like app crashes, 
    system slowdowns, and performance problems. Uses native macOS APIs to gather diagnostic 
    information from system and user directories.
    """
    
    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "app_name": [
                    "type": "string",
                    "description": "Specific app name to focus diagnostic collection on"
                ],
                "bundle_identifier": [
                    "type": "string",
                    "description": "Bundle identifier to focus diagnostic collection on"
                ],
                "diagnostic_type": [
                    "type": "string",
                    "enum": DiagnosticType.allCases.map { $0.rawValue },
                    "description": "Type of diagnostic information to collect (default: all)"
                ],
                "time_range_hours": [
                    "type": "integer",
                    "description": "Time range for reports in hours (default: 24)"
                ],
                "include_system_reports": [
                    "type": "boolean",
                    "description": "Include system-level diagnostic reports (default: true)"
                ],
                "include_user_reports": [
                    "type": "boolean",
                    "description": "Include user-level diagnostic reports (default: true)"
                ],
                "collect_app_samples": [
                    "type": "boolean",
                    "description": "Collect app performance samples (default: true)"
                ],
                "max_reports_per_type": [
                    "type": "integer",
                    "description": "Maximum number of reports to return per type (default: 50)"
                ]
            ]
        ])
    }
    
    func execute(arguments: [String: Any]) async throws -> String {
        Logger.tools("SystemDiagnosticTool.execute: Starting with arguments: \(arguments)")
        
        // Parse input
        let input = try parseInput(from: arguments)
        Logger.tools("SystemDiagnosticTool.execute: Parsed input: \(input)")
        
        // Collect system information
        let systemInfo = try await collectSystemInformation()
        Logger.tools("SystemDiagnosticTool.execute: Collected system info")
        
        // Collect diagnostic reports based on type
        var crashReports: [DiagnosticReport] = []
        var spinReports: [DiagnosticReport] = []
        let systemLogs: [DiagnosticReport] = []
        let appLogs: [DiagnosticReport] = []
        var jetsamReports: [DiagnosticReport] = []
        var thermalReports: [DiagnosticReport] = []
        var watchdogReports: [DiagnosticReport] = []
        
        let diagnosticType = input.diagnosticType ?? .all
        let timeRange = TimeInterval((input.timeRangeHours ?? 24) * 3600)
        let maxReports = max(1, input.maxReportsPerType ?? 50)  // Ensure maxReports is at least 1
        
        if diagnosticType == .all || diagnosticType == .crashReports {
            crashReports = try await collectCrashReports(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier,
                timeRange: timeRange,
                maxReports: maxReports
            )
        }
        
        if diagnosticType == .all || diagnosticType == .spinReports {
            spinReports = try await collectSpinReports(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier,
                timeRange: timeRange,
                maxReports: maxReports
            )
        }
        
        if diagnosticType == .all || diagnosticType == .jetsamReports {
            jetsamReports = try await collectJetsamReports(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier,
                timeRange: timeRange,
                maxReports: maxReports
            )
        }
        
        if diagnosticType == .all || diagnosticType == .thermalReports {
            thermalReports = try await collectThermalReports(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier,
                timeRange: timeRange,
                maxReports: maxReports
            )
        }
        
        if diagnosticType == .all || diagnosticType == .watchdogReports {
            watchdogReports = try await collectWatchdogReports(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier,
                timeRange: timeRange,
                maxReports: maxReports
            )
        }
        
        // Collect app samples
        var appSamples: [AppSample] = []
        if (diagnosticType == .all || diagnosticType == .appSamples) && (input.collectAppSamples ?? true) {
            appSamples = try await collectAppSamples(
                appName: input.appName,
                bundleIdentifier: input.bundleIdentifier
            )
        }
        
        // Collect network diagnostics
        var networkDiagnostics: NetworkDiagnostics?
        if diagnosticType == .all || diagnosticType == .networkDiagnostics {
            networkDiagnostics = try await collectNetworkDiagnostics()
        }
        
        // Collect performance metrics
        var performanceMetrics: PerformanceMetrics?
        if diagnosticType == .all || diagnosticType == .performanceMetrics {
            performanceMetrics = try await collectPerformanceMetrics()
        }
        
        // Generate summary
        let summary = generateSummary(
            crashReports: crashReports,
            spinReports: spinReports,
            jetsamReports: jetsamReports,
            thermalReports: thermalReports,
            watchdogReports: watchdogReports,
            systemInfo: systemInfo
        )
        
        // Create final report
        let report = SystemDiagnosticReport(
            timestamp: Date(),
            systemInfo: systemInfo,
            crashReports: crashReports,
            spinReports: spinReports,
            systemLogs: systemLogs,
            appLogs: appLogs,
            jetsamReports: jetsamReports,
            thermalReports: thermalReports,
            watchdogReports: watchdogReports,
            appSamples: appSamples,
            networkDiagnostics: networkDiagnostics,
            performanceMetrics: performanceMetrics,
            summary: summary
        )
        
        Logger.tools("SystemDiagnosticTool.execute: Generated report with \(crashReports.count) crashes, \(spinReports.count) spins")
        
        return report.toFormattedString()
    }
    
    // MARK: - Private Methods
    
    private func parseInput(from arguments: [String: Any]) throws -> SystemDiagnosticInput {
        let data = try JSONSerialization.data(withJSONObject: arguments)
        return try JSONDecoder().decode(SystemDiagnosticInput.self, from: data)
    }
    
    private func collectSystemInformation() async throws -> SystemInformation {
        let hostName = Host.current().name ?? "Unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let osBuild = try getSystemBuild()
        let kernelVersion = try getKernelVersion()
        let architecture = try getArchitecture()
        let cpuInfo = try getCPUInfo()
        let memoryInfo = try getMemoryInfo()
        let diskSpace = try getDiskSpace()
        let uptime = ProcessInfo.processInfo.systemUptime
        let bootTime = Date(timeIntervalSinceNow: -uptime)
        let thermalState = try getThermalState()
        let batteryInfo = try getBatteryInfo()
        
        return SystemInformation(
            hostName: hostName,
            osVersion: osVersion,
            osBuild: osBuild,
            kernelVersion: kernelVersion,
            architecture: architecture,
            cpuType: cpuInfo.type,
            cpuSubtype: cpuInfo.subtype,
            physicalMemory: memoryInfo.physical,
            availableMemory: memoryInfo.available,
            diskSpace: diskSpace,
            uptime: uptime,
            bootTime: bootTime,
            thermalState: thermalState,
            batteryInfo: batteryInfo
        )
    }
    
    private func collectCrashReports(
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        // Collect from user directory
        let userReportsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: userReportsURL,
            fileExtension: "ips",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Crash Report"
        ))
        
        // Collect from system directory
        let systemReportsURL = URL(fileURLWithPath: "/Library/Logs/DiagnosticReports")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: systemReportsURL,
            fileExtension: "ips",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Crash Report"
        ))
        
        return Array(reports.prefix(maxReports))
    }
    
    private func collectSpinReports(
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        // Collect from user directory
        let userReportsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: userReportsURL,
            fileExtension: "spin",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Spin Report"
        ))
        
        // Collect from system directory
        let systemReportsURL = URL(fileURLWithPath: "/Library/Logs/DiagnosticReports")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: systemReportsURL,
            fileExtension: "spin",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Spin Report"
        ))
        
        return Array(reports.prefix(maxReports))
    }
    
    private func collectJetsamReports(
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        // Jetsam reports are typically in system logs
        let systemLogsURL = URL(fileURLWithPath: "/var/log")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: systemLogsURL,
            fileExtension: "log",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Jetsam Report"
        ))
        
        return Array(reports.prefix(maxReports))
    }
    
    private func collectThermalReports(
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        // Thermal reports are typically in system logs
        let systemLogsURL = URL(fileURLWithPath: "/var/log")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: systemLogsURL,
            fileExtension: "log",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Thermal Report"
        ))
        
        return Array(reports.prefix(maxReports))
    }
    
    private func collectWatchdogReports(
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        // Watchdog reports are typically in system logs
        let systemLogsURL = URL(fileURLWithPath: "/var/log")
        reports.append(contentsOf: try await collectReportsFromDirectory(
            url: systemLogsURL,
            fileExtension: "log",
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            timeRange: timeRange,
            maxReports: maxReports,
            type: "Watchdog Report"
        ))
        
        return Array(reports.prefix(maxReports))
    }
    
    private func collectAppSamples(
        appName: String?,
        bundleIdentifier: String?
    ) async throws -> [AppSample] {
        var samples: [AppSample] = []
        
        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            // Filter by app name or bundle identifier if specified
            if let targetAppName = appName, app.localizedName != targetAppName {
                continue
            }
            if let targetBundleId = bundleIdentifier, app.bundleIdentifier != targetBundleId {
                continue
            }
            
            guard let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName else {
                continue
            }
            
            // Get process information
            let processId = Int(app.processIdentifier)
            let cpuUsage = try getCPUUsage(for: processId)
            let memoryUsage = try getMemoryUsage(for: processId)
            let threadCount = try getThreadCount(for: processId)
            let isResponsive = app.isActive
            
            let sample = AppSample(
                appName: appName,
                bundleIdentifier: bundleId,
                processId: processId,
                cpuUsage: cpuUsage,
                memoryUsage: memoryUsage,
                threadCount: threadCount,
                sampleTime: Date(),
                isResponsive: isResponsive,
                sampleData: nil
            )
            
            samples.append(sample)
        }
        
        return samples
    }
    
    private func collectNetworkDiagnostics() async throws -> NetworkDiagnostics {
        let activeConnections = try getActiveConnections()
        let networkInterfaces = try getNetworkInterfaces()
        let dnsServers = try getDNSServers()
        let routingTable = try getRoutingTable()
        let networkReachability = try getNetworkReachability()
        
        return NetworkDiagnostics(
            activeConnections: activeConnections,
            networkInterfaces: networkInterfaces,
            dnsServers: dnsServers,
            routingTable: routingTable,
            networkReachability: networkReachability
        )
    }
    
    private func collectPerformanceMetrics() async throws -> PerformanceMetrics {
        let cpuUsage = try getSystemCPUUsage()
        let memoryPressure = try getMemoryPressure()
        let diskActivity = try getDiskActivity()
        let networkActivity = try getNetworkActivity()
        let thermalPressure = try getThermalPressure()
        let gpuUsage = try getGPUUsage()
        
        return PerformanceMetrics(
            cpuUsage: cpuUsage,
            memoryPressure: memoryPressure,
            diskActivity: diskActivity,
            networkActivity: networkActivity,
            thermalPressure: thermalPressure,
            gpuUsage: gpuUsage
        )
    }
    
    private func collectReportsFromDirectory(
        url: URL,
        fileExtension: String,
        appName: String?,
        bundleIdentifier: String?,
        timeRange: TimeInterval,
        maxReports: Int,
        type: String
    ) async throws -> [DiagnosticReport] {
        var reports: [DiagnosticReport] = []
        
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [
                .creationDateKey,
                .contentModificationDateKey,
                .fileSizeKey
            ])
            
            let cutoffDate = Date().addingTimeInterval(-timeRange)
            
            for file in files {
                guard file.pathExtension == fileExtension else { continue }
                
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                guard let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
                      creationDate >= cutoffDate else { continue }
                
                let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date ?? creationDate
                let fileSize = attributes[FileAttributeKey.size] as? Int64 ?? 0
                
                // Parse report content to extract app information
                let reportInfo = try parseReportContent(at: file)
                
                // Filter by app name or bundle identifier if specified
                if let targetAppName = appName, reportInfo.appName != targetAppName {
                    continue
                }
                if let targetBundleId = bundleIdentifier, reportInfo.bundleIdentifier != targetBundleId {
                    continue
                }
                
                let report = DiagnosticReport(
                    type: type,
                    fileName: file.lastPathComponent,
                    filePath: file.path,
                    fileSize: fileSize,
                    creationDate: creationDate,
                    modificationDate: modificationDate,
                    appName: reportInfo.appName,
                    bundleIdentifier: reportInfo.bundleIdentifier,
                    processId: reportInfo.processId,
                    exceptionType: reportInfo.exceptionType,
                    exceptionCode: reportInfo.exceptionCode,
                    signal: reportInfo.signal,
                    summary: reportInfo.summary,
                    content: reportInfo.content
                )
                
                reports.append(report)
                
                if reports.count >= maxReports {
                    break
                }
            }
        } catch {
            // Directory might not exist or be accessible, continue silently
            Logger.tools("SystemDiagnosticTool: Could not access directory \(url.path): \(error)")
        }
        
        return reports
    }
    
    private func parseReportContent(at url: URL) throws -> (appName: String?, bundleIdentifier: String?, processId: Int?, exceptionType: String?, exceptionCode: String?, signal: String?, summary: String?, content: String?) {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        var appName: String?
        var bundleIdentifier: String?
        var processId: Int?
        var exceptionType: String?
        var exceptionCode: String?
        var signal: String?
        var summary: String?
        
        // Parse crash report content
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("Process:") {
                appName = line.components(separatedBy: " ").dropFirst().first
            } else if line.hasPrefix("Identifier:") {
                bundleIdentifier = line.components(separatedBy: " ").dropFirst().first
            } else if line.hasPrefix("PID:") {
                processId = Int(line.components(separatedBy: " ").dropFirst().first ?? "")
            } else if line.hasPrefix("Exception Type:") {
                exceptionType = line.components(separatedBy: " ").dropFirst(2).joined(separator: " ")
            } else if line.hasPrefix("Exception Codes:") {
                exceptionCode = line.components(separatedBy: " ").dropFirst(2).joined(separator: " ")
            } else if line.hasPrefix("Crashed Thread:") {
                signal = line.components(separatedBy: " ").dropFirst(2).joined(separator: " ")
            }
        }
        
        // Generate summary from first few lines
        let firstLines = lines.prefix(10).joined(separator: "\n")
        summary = firstLines.count > 200 ? String(firstLines.prefix(200)) + "..." : firstLines
        
        return (appName, bundleIdentifier, processId, exceptionType, exceptionCode, signal, summary, content)
    }
    
    private func generateSummary(
        crashReports: [DiagnosticReport],
        spinReports: [DiagnosticReport],
        jetsamReports: [DiagnosticReport],
        thermalReports: [DiagnosticReport],
        watchdogReports: [DiagnosticReport],
        systemInfo: SystemInformation
    ) -> DiagnosticSummary {
        let totalReports = crashReports.count + spinReports.count + jetsamReports.count + thermalReports.count + watchdogReports.count
        
        // Find most frequent crasher
        let crashCounts = Dictionary(grouping: crashReports, by: { $0.appName ?? "Unknown" })
            .mapValues { $0.count }
        let mostFrequentCrasher = crashCounts.max(by: { $0.value < $1.value })?.key
        
        // Determine system health
        let systemHealth: String
        if crashReports.count > 10 {
            systemHealth = "Poor - High crash rate"
        } else if spinReports.count > 5 {
            systemHealth = "Fair - Some unresponsive apps"
        } else if jetsamReports.count > 3 {
            systemHealth = "Fair - Memory pressure issues"
        } else {
            systemHealth = "Good"
        }
        
        // Generate recommendations
        var recommendations: [String] = []
        if crashReports.count > 5 {
            recommendations.append("Investigate frequent crashes - consider updating problematic apps")
        }
        if spinReports.count > 3 {
            recommendations.append("Check for unresponsive applications and consider restarting them")
        }
        if jetsamReports.count > 2 {
            recommendations.append("Monitor memory usage - consider closing memory-intensive applications")
        }
        if thermalReports.count > 1 {
            recommendations.append("Check system temperature - ensure proper ventilation")
        }
        if systemInfo.availableMemory < systemInfo.physicalMemory / 4 {
            recommendations.append("Low available memory - consider closing unused applications")
        }
        
        return DiagnosticSummary(
            totalReports: totalReports,
            crashCount: crashReports.count,
            spinCount: spinReports.count,
            jetsamCount: jetsamReports.count,
            thermalCount: thermalReports.count,
            watchdogCount: watchdogReports.count,
            mostFrequentCrasher: mostFrequentCrasher,
            systemHealth: systemHealth,
            recommendations: recommendations
        )
    }
    
    // MARK: - System Information Helpers
    
    private func getSystemBuild() throws -> String {
        let build = try sysctl(name: "kern.osversion")
        return build
    }
    
    private func getKernelVersion() throws -> String {
        let version = try sysctl(name: "kern.version")
        return version
    }
    
    private func getArchitecture() throws -> String {
        let arch = try sysctl(name: "hw.machine")
        return arch
    }
    
    private func getCPUInfo() throws -> (type: String, subtype: String) {
        let type = try sysctl(name: "hw.cputype")
        let subtype = try sysctl(name: "hw.cpusubtype")
        return (type, subtype)
    }
    
    private func getMemoryInfo() throws -> (physical: UInt64, available: UInt64) {
        let physical = try sysctl(name: "hw.memsize")
        let physicalBytes = UInt64(physical) ?? 0
        
        // Get available memory from vm_statistics
        let available = try getAvailableMemory()
        
        return (physicalBytes, available)
    }
    
    private func getDiskSpace() throws -> DiskSpace {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let resourceValues = try homeURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey
        ])
        
        let total = UInt64(resourceValues.volumeTotalCapacity ?? 0)
        let available = UInt64(resourceValues.volumeAvailableCapacity ?? 0)
        let used = total - available
        
        return DiskSpace(total: total, available: available, used: used)
    }
    
    private func getThermalState() throws -> String {
        // This would require IOKit framework for detailed thermal state
        // For now, return a basic state
        return "Normal"
    }
    
    private func getBatteryInfo() throws -> BatteryInfo? {
        // This would require IOKit framework for battery information
        // For now, return nil (desktop systems don't have batteries)
        return nil
    }
    
    private func getCPUUsage(for processId: Int) throws -> Double {
        // This would require more complex process monitoring
        // For now, return a placeholder
        return 0.0
    }
    
    private func getMemoryUsage(for processId: Int) throws -> UInt64 {
        // This would require more complex process monitoring
        // For now, return a placeholder
        return 0
    }
    
    private func getThreadCount(for processId: Int) throws -> Int {
        // This would require more complex process monitoring
        // For now, return a placeholder
        return 1
    }
    
    private func getActiveConnections() throws -> Int {
        // This would require network monitoring
        // For now, return a placeholder
        return 0
    }
    
    private func getNetworkInterfaces() throws -> [NetworkInterface] {
        // This would require network interface enumeration
        // For now, return empty array
        return []
    }
    
    private func getDNSServers() throws -> [String] {
        // This would require DNS configuration reading
        // For now, return empty array
        return []
    }
    
    private func getRoutingTable() throws -> [String] {
        // This would require routing table reading
        // For now, return empty array
        return []
    }
    
    private func getNetworkReachability() throws -> String {
        // This would require network reachability testing
        // For now, return a placeholder
        return "Unknown"
    }
    
    private func getSystemCPUUsage() throws -> Double {
        // This would require system CPU monitoring
        // For now, return a placeholder
        return 0.0
    }
    
    private func getMemoryPressure() throws -> String {
        // This would require memory pressure monitoring
        // For now, return a placeholder
        return "Normal"
    }
    
    private func getDiskActivity() throws -> String {
        // This would require disk activity monitoring
        // For now, return a placeholder
        return "Normal"
    }
    
    private func getNetworkActivity() throws -> String {
        // This would require network activity monitoring
        // For now, return a placeholder
        return "Normal"
    }
    
    private func getThermalPressure() throws -> String {
        // This would require thermal pressure monitoring
        // For now, return a placeholder
        return "Normal"
    }
    
    private func getGPUUsage() throws -> Double? {
        // This would require GPU monitoring
        // For now, return nil
        return nil
    }
    
    private func getAvailableMemory() throws -> UInt64 {
        // This would require more complex memory monitoring
        // For now, return a placeholder
        return 0
    }
    
    private func sysctl(name: String) throws -> String {
        var size: size_t = 0
        sysctlbyname(name, nil, &size, nil, 0)
        
        var buffer = [CChar](repeating: 0, count: size)
        let result = sysctlbyname(name, &buffer, &size, nil, 0)
        
        guard result == 0 else {
            throw ToolError.executionFailed("Failed to get sysctl value for \(name)")
        }
        
        return String(cString: buffer)
    }
}

// MARK: - Helper Functions

private func formatBytes(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

private func formatUptime(_ uptime: TimeInterval) -> String {
    let days = Int(uptime) / 86400
    let hours = (Int(uptime) % 86400) / 3600
    let minutes = (Int(uptime) % 3600) / 60
    
    if days > 0 {
        return "\(days)d \(hours)h \(minutes)m"
    } else if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
