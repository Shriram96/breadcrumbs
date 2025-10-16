//
//  SystemDiagnosticToolTests.swift
//  breadcrumbsTests
//
//  Tests for SystemDiagnosticTool
//

@testable import breadcrumbs
import XCTest

@MainActor
final class SystemDiagnosticToolTests: XCTestCase {
    var tool: SystemDiagnosticTool!

    override func setUp() {
        super.setUp()
        tool = SystemDiagnosticTool()
    }

    override func tearDown() {
        tool = nil
        super.tearDown()
    }

    // MARK: - Tool Protocol Tests

    func testToolName() {
        XCTAssertEqual(tool.name, "system_diagnostic")
    }

    func testToolDescription() {
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertTrue(tool.description.contains("diagnostic"))
        XCTAssertTrue(tool.description.contains("crash"))
    }

    func testParametersSchema() throws {
        let schema = tool.parametersSchema.jsonSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = try XCTUnwrap(schema["properties"] as? [String: [String: Any]])

        // Check required properties
        XCTAssertNotNil(properties["app_name"])
        XCTAssertNotNil(properties["bundle_identifier"])
        XCTAssertNotNil(properties["diagnostic_type"])
        XCTAssertNotNil(properties["time_range_hours"])
        XCTAssertNotNil(properties["include_system_reports"])
        XCTAssertNotNil(properties["include_user_reports"])
        XCTAssertNotNil(properties["collect_app_samples"])
        XCTAssertNotNil(properties["max_reports_per_type"])
    }

    // MARK: - Input Parsing Tests

    func testParseInputWithAllParameters() async throws {
        let arguments: [String: Any] = [
            "app_name": "TestApp",
            "bundle_identifier": "com.test.app",
            "diagnostic_type": "crash_reports",
            "time_range_hours": 48,
            "include_system_reports": true,
            "include_user_reports": false,
            "collect_app_samples": true,
            "max_reports_per_type": 25,
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("SYSTEM DIAGNOSTIC REPORT"))
    }

    func testParseInputWithMinimalParameters() async throws {
        let arguments = [String: Any]()

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("SYSTEM DIAGNOSTIC REPORT"))
    }

    func testParseInputWithInvalidDiagnosticType() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "invalid_type",
        ]

        // Should throw an error for invalid diagnostic type
        do {
            _ = try await tool.execute(arguments: arguments)
            XCTFail("Should have thrown an error for invalid diagnostic type")
        } catch {
            // Expected behavior - tool should throw a DecodingError for invalid enum values
            XCTAssertTrue(error is DecodingError, "Expected DecodingError but got: \(type(of: error))")
        }
    }

    // MARK: - Diagnostic Type Tests

    func testDiagnosticTypeAll() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "all",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertTrue(result.contains("SYSTEM INFORMATION"))
        XCTAssertTrue(result.contains("SUMMARY"))
    }

    func testDiagnosticTypeCrashReports() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertTrue(result.contains("SYSTEM INFORMATION"))
        XCTAssertTrue(result.contains("SUMMARY"))
    }

    func testDiagnosticTypeSpinReports() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "spin_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertTrue(result.contains("SYSTEM INFORMATION"))
        XCTAssertTrue(result.contains("SUMMARY"))
    }

    func testDiagnosticTypeSystemInfo() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "system_info",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertTrue(result.contains("SYSTEM INFORMATION"))
        XCTAssertTrue(result.contains("Host:"))
        XCTAssertTrue(result.contains("OS:"))
    }

    // MARK: - App Filtering Tests

    func testFilterByAppName() async throws {
        // Ensure tool is properly initialized
        XCTAssertNotNil(tool, "Tool should be initialized in setUp()")

        let arguments: [String: Any] = [
            "app_name": "Safari",
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        // Note: Actual filtering depends on available reports
    }

    func testFilterByBundleIdentifier() async throws {
        // Ensure tool is properly initialized
        XCTAssertNotNil(tool, "Tool should be initialized in setUp()")

        let arguments: [String: Any] = [
            "bundle_identifier": "com.apple.Safari",
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        // Note: Actual filtering depends on available reports
    }

    // MARK: - Time Range Tests

    func testTimeRangeFiltering() async throws {
        let arguments: [String: Any] = [
            "time_range_hours": 1,
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    func testTimeRangeWithLargeValue() async throws {
        let arguments: [String: Any] = [
            "time_range_hours": 8760, // 1 year
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Report Limits Tests

    func testMaxReportsPerType() async throws {
        let arguments: [String: Any] = [
            "max_reports_per_type": 5,
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    func testMaxReportsWithZero() async throws {
        let arguments: [String: Any] = [
            "max_reports_per_type": 0,
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - System Information Tests

    func testSystemInformationCollection() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "system_info",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertTrue(result.contains("Host:"))
        XCTAssertTrue(result.contains("OS:"))
        XCTAssertTrue(result.contains("Architecture:"))
        XCTAssertTrue(result.contains("Memory:"))
        XCTAssertTrue(result.contains("Disk:"))
        XCTAssertTrue(result.contains("Uptime:"))
    }

    // MARK: - App Samples Tests

    func testAppSamplesCollection() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "app_samples",
            "collect_app_samples": true,
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        // Note: Actual samples depend on running applications
    }

    func testAppSamplesDisabled() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "all",
            "collect_app_samples": false,
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        // Should not contain app samples section
    }

    // MARK: - Network Diagnostics Tests

    func testNetworkDiagnostics() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "network_diagnostics",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Performance Metrics Tests

    func testPerformanceMetrics() async throws {
        let arguments: [String: Any] = [
            "diagnostic_type": "performance_metrics",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testInvalidArguments() async {
        let arguments: [String: Any] = [
            "invalid_parameter": "invalid_value",
        ]

        // Should not throw, but handle gracefully
        do {
            _ = try await tool.execute(arguments: arguments)
        } catch {
            XCTFail("Tool should handle invalid arguments gracefully: \(error)")
        }
    }

    func testMalformedArguments() async {
        let arguments: [String: Any] = [
            "time_range_hours": "not_a_number",
        ]

        // Should throw an error for malformed arguments
        do {
            _ = try await tool.execute(arguments: arguments)
            XCTFail("Should have thrown an error for malformed arguments")
        } catch {
            // Expected behavior - tool should throw an error for invalid input types
            XCTAssertTrue(error is DecodingError || error is ToolError)
        }
    }

    // MARK: - Output Format Tests

    func testOutputFormat() async throws {
        let arguments = [String: Any]()

        let result = try await tool.execute(arguments: arguments)

        // Check for expected sections
        XCTAssertTrue(result.contains("=== SYSTEM DIAGNOSTIC REPORT ==="))
        XCTAssertTrue(result.contains("=== SYSTEM INFORMATION ==="))
        XCTAssertTrue(result.contains("=== SUMMARY ==="))

        // Check for timestamp
        XCTAssertTrue(result.contains("Generated:"))
    }

    func testOutputContainsSystemInfo() async throws {
        let arguments = [String: Any]()

        let result = try await tool.execute(arguments: arguments)

        // Check for system information fields
        XCTAssertTrue(result.contains("Host:"))
        XCTAssertTrue(result.contains("OS:"))
        XCTAssertTrue(result.contains("Architecture:"))
        XCTAssertTrue(result.contains("Memory:"))
        XCTAssertTrue(result.contains("Disk:"))
        XCTAssertTrue(result.contains("Uptime:"))
    }

    // MARK: - Integration Tests

    @MainActor
    func testToolRegistryIntegration() {
        let registry = ToolRegistry(forTesting: true)
        registry.register(tool)

        let retrievedTool = registry.getTool(named: "system_diagnostic")
        XCTAssertNotNil(retrievedTool)
        XCTAssertEqual(retrievedTool?.name, "system_diagnostic")
    }

    @MainActor
    func testToolExecutionThroughRegistry() async throws {
        let registry = ToolRegistry(forTesting: true)
        registry.register(tool)

        let arguments: [String: Any] = [
            "diagnostic_type": "system_info",
        ]

        let result = try await registry.executeTool(name: "system_diagnostic", arguments: arguments)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("SYSTEM DIAGNOSTIC REPORT"))
    }

    // MARK: - Performance Tests

    func testExecutionPerformance() {
        // Ensure tool is properly initialized
        XCTAssertNotNil(tool, "Tool should be initialized in setUp()")

        let arguments: [String: Any] = [
            "diagnostic_type": "system_info",
            "max_reports_per_type": 10,
        ]

        measure {
            let expectation = XCTestExpectation(description: "Tool execution")
            Task {
                do {
                    _ = try await tool.execute(arguments: arguments)
                    expectation.fulfill()
                } catch {
                    XCTFail("Tool execution failed: \(error)")
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Edge Cases Tests

    func testEmptyAppName() async throws {
        let arguments: [String: Any] = [
            "app_name": "",
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    func testEmptyBundleIdentifier() async throws {
        let arguments: [String: Any] = [
            "bundle_identifier": "",
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    func testNegativeTimeRange() async throws {
        let arguments: [String: Any] = [
            "time_range_hours": -1,
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    func testNegativeMaxReports() async throws {
        let arguments: [String: Any] = [
            "max_reports_per_type": -1,
            "diagnostic_type": "crash_reports",
        ]

        let result = try await tool.execute(arguments: arguments)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Data Model Tests

    func testSystemDiagnosticInputCodable() throws {
        let input = SystemDiagnosticInput(
            appName: "TestApp",
            bundleIdentifier: "com.test.app",
            diagnosticType: .crashReports,
            timeRangeHours: 24,
            includeSystemReports: true,
            includeUserReports: true,
            collectAppSamples: true,
            maxReportsPerType: 50
        )

        let data = try JSONEncoder().encode(input)
        let decoded = try JSONDecoder().decode(SystemDiagnosticInput.self, from: data)

        XCTAssertEqual(input.appName, decoded.appName)
        XCTAssertEqual(input.bundleIdentifier, decoded.bundleIdentifier)
        XCTAssertEqual(input.diagnosticType, decoded.diagnosticType)
        XCTAssertEqual(input.timeRangeHours, decoded.timeRangeHours)
        XCTAssertEqual(input.includeSystemReports, decoded.includeSystemReports)
        XCTAssertEqual(input.includeUserReports, decoded.includeUserReports)
        XCTAssertEqual(input.collectAppSamples, decoded.collectAppSamples)
        XCTAssertEqual(input.maxReportsPerType, decoded.maxReportsPerType)
    }

    func testDiagnosticTypeEnum() {
        let allTypes = DiagnosticType.allCases
        XCTAssertTrue(allTypes.contains(.all))
        XCTAssertTrue(allTypes.contains(.crashReports))
        XCTAssertTrue(allTypes.contains(.spinReports))
        XCTAssertTrue(allTypes.contains(.systemLogs))
        XCTAssertTrue(allTypes.contains(.appLogs))
        XCTAssertTrue(allTypes.contains(.jetsamReports))
        XCTAssertTrue(allTypes.contains(.thermalReports))
        XCTAssertTrue(allTypes.contains(.watchdogReports))
        XCTAssertTrue(allTypes.contains(.systemInfo))
        XCTAssertTrue(allTypes.contains(.appSamples))
        XCTAssertTrue(allTypes.contains(.networkDiagnostics))
        XCTAssertTrue(allTypes.contains(.performanceMetrics))
    }

    func testSystemInformationCodable() throws {
        let systemInfo = SystemInformation(
            hostName: "TestHost",
            osVersion: "macOS 15.0",
            osBuild: "23A344",
            kernelVersion: "Darwin Kernel Version 23.0.0",
            architecture: "arm64",
            cpuType: "ARM64",
            cpuSubtype: "ARM64_ALL",
            physicalMemory: 8_589_934_592,
            availableMemory: 4_294_967_296,
            diskSpace: DiskSpace(total: 1_000_000_000_000, available: 500_000_000_000, used: 500_000_000_000),
            uptime: 86400,
            bootTime: Date(),
            thermalState: "Normal",
            batteryInfo: nil
        )

        let data = try JSONEncoder().encode(systemInfo)
        let decoded = try JSONDecoder().decode(SystemInformation.self, from: data)

        XCTAssertEqual(systemInfo.hostName, decoded.hostName)
        XCTAssertEqual(systemInfo.osVersion, decoded.osVersion)
        XCTAssertEqual(systemInfo.architecture, decoded.architecture)
        XCTAssertEqual(systemInfo.physicalMemory, decoded.physicalMemory)
    }

    func testDiagnosticReportCodable() throws {
        let report = DiagnosticReport(
            type: "Crash Report",
            fileName: "TestApp_2023-10-01-123456.ips",
            filePath: "/path/to/report.ips",
            fileSize: 1024,
            creationDate: Date(),
            modificationDate: Date(),
            appName: "TestApp",
            bundleIdentifier: "com.test.app",
            processID: 12345,
            exceptionType: "EXC_BAD_ACCESS",
            exceptionCode: "KERN_INVALID_ADDRESS",
            signal: "SIGSEGV",
            summary: "Test crash summary",
            content: "Full crash report content"
        )

        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(DiagnosticReport.self, from: data)

        XCTAssertEqual(report.type, decoded.type)
        XCTAssertEqual(report.fileName, decoded.fileName)
        XCTAssertEqual(report.appName, decoded.appName)
        XCTAssertEqual(report.bundleIdentifier, decoded.bundleIdentifier)
        XCTAssertEqual(report.processID, decoded.processID)
        XCTAssertEqual(report.exceptionType, decoded.exceptionType)
    }

    func testAppSampleCodable() throws {
        let sample = AppSample(
            appName: "TestApp",
            bundleIdentifier: "com.test.app",
            processID: 12345,
            cpuUsage: 25.5,
            memoryUsage: 1_048_576,
            threadCount: 8,
            sampleTime: Date(),
            isResponsive: true,
            sampleData: "Sample data"
        )

        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(AppSample.self, from: data)

        XCTAssertEqual(sample.appName, decoded.appName)
        XCTAssertEqual(sample.bundleIdentifier, decoded.bundleIdentifier)
        XCTAssertEqual(sample.processID, decoded.processID)
        XCTAssertEqual(sample.cpuUsage, decoded.cpuUsage, accuracy: 0.1)
        XCTAssertEqual(sample.memoryUsage, decoded.memoryUsage)
        XCTAssertEqual(sample.threadCount, decoded.threadCount)
        XCTAssertEqual(sample.isResponsive, decoded.isResponsive)
    }

    func testDiagnosticSummaryCodable() throws {
        let summary = DiagnosticSummary(
            totalReports: 10,
            crashCount: 5,
            spinCount: 2,
            jetsamCount: 1,
            thermalCount: 1,
            watchdogCount: 1,
            mostFrequentCrasher: "TestApp",
            systemHealth: "Fair",
            recommendations: ["Update TestApp", "Check memory usage"]
        )

        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(DiagnosticSummary.self, from: data)

        XCTAssertEqual(summary.totalReports, decoded.totalReports)
        XCTAssertEqual(summary.crashCount, decoded.crashCount)
        XCTAssertEqual(summary.spinCount, decoded.spinCount)
        XCTAssertEqual(summary.mostFrequentCrasher, decoded.mostFrequentCrasher)
        XCTAssertEqual(summary.systemHealth, decoded.systemHealth)
        XCTAssertEqual(summary.recommendations, decoded.recommendations)
    }
}
