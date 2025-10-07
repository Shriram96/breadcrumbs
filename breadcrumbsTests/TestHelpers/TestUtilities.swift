//
//  TestUtilities.swift
//  breadcrumbsTests
//
//  Test utilities and helpers for unit tests
//

import XCTest
import Foundation
@testable import breadcrumbs

/// Error thrown when an operation times out
struct TimeoutError: Error {}

/// Test utilities and helpers for unit tests
final class TestUtilities {
    
    // MARK: - Mock Data Generators
    
    /// Generate a test ChatMessage
    static func createTestChatMessage(
        role: MessageRole = .user,
        content: String = "Test message",
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) -> ChatMessage {
        return ChatMessage(
            role: role,
            content: content,
            toolCalls: toolCalls,
            toolCallId: toolCallId
        )
    }
    
    /// Generate a test ToolCall
    static func createTestToolCall(
        id: String = "test_call_1",
        name: String = "test_tool",
        arguments: String = "{}"
    ) -> ToolCall {
        return ToolCall(id: id, name: name, arguments: arguments)
    }
    
    /// Generate a test ToolResult
    static func createTestToolResult(
        toolCallId: String = "test_call_1",
        result: String = "Test result"
    ) -> ToolResult {
        return ToolResult(toolCallId: toolCallId, result: result)
    }
    
    /// Generate a test VPNDetectorInput
    static func createTestVPNDetectorInput(
        interfaceName: String? = "utun0"
    ) -> VPNDetectorInput {
        return VPNDetectorInput(interfaceName: interfaceName)
    }
    
    /// Generate a test VPNDetectorOutput
    static func createTestVPNDetectorOutput(
        isConnected: Bool = true,
        vpnType: String? = "IKEv2",
        interfaceName: String? = "utun0",
        ipAddress: String? = "192.168.1.100",
        connectionStatus: String? = "Connected",
        connectedDate: Date? = Date(),
        timestamp: Date = Date(),
        serverAddress: String? = "vpn.example.com",
        remoteIdentifier: String? = "remote-id",
        localIdentifier: String? = "local-id",
        displayName: String? = "Test VPN",
        hasCertificate: Bool = false,
        certificateInfo: String? = nil
    ) -> VPNDetectorOutput {
        return VPNDetectorOutput(
            isConnected: isConnected,
            vpnType: vpnType,
            interfaceName: interfaceName,
            ipAddress: ipAddress,
            connectionStatus: connectionStatus,
            connectedDate: connectedDate,
            timestamp: timestamp,
            serverAddress: serverAddress,
            remoteIdentifier: remoteIdentifier,
            localIdentifier: localIdentifier,
            displayName: displayName,
            hasCertificate: hasCertificate,
            certificateInfo: certificateInfo
        )
    }
    
    /// Generate a test Item
    static func createTestItem(
        timestamp: Date = Date()
    ) -> Item {
        return Item(timestamp: timestamp)
    }
    
    // MARK: - Test Assertions
    
    /// Assert that a ChatMessage has the expected properties
    static func assertChatMessage(
        _ message: ChatMessage,
        role: MessageRole,
        content: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(message.role, role, file: file, line: line)
        XCTAssertEqual(message.content, content, file: file, line: line)
    }
    
    /// Assert that a ToolCall has the expected properties
    static func assertToolCall(
        _ toolCall: ToolCall,
        id: String,
        name: String,
        arguments: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(toolCall.id, id, file: file, line: line)
        XCTAssertEqual(toolCall.name, name, file: file, line: line)
        XCTAssertEqual(toolCall.arguments, arguments, file: file, line: line)
    }
    
    /// Assert that a VPNDetectorOutput has the expected properties
    static func assertVPNDetectorOutput(
        _ output: VPNDetectorOutput,
        isConnected: Bool,
        vpnType: String? = nil,
        interfaceName: String? = nil,
        ipAddress: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(output.isConnected, isConnected, file: file, line: line)
        if let expectedVpnType = vpnType {
            XCTAssertEqual(output.vpnType, expectedVpnType, file: file, line: line)
        }
        if let expectedInterfaceName = interfaceName {
            XCTAssertEqual(output.interfaceName, expectedInterfaceName, file: file, line: line)
        }
        if let expectedIpAddress = ipAddress {
            XCTAssertEqual(output.ipAddress, expectedIpAddress, file: file, line: line)
        }
    }
    
    // MARK: - Async Test Helpers
    
    /// Execute an async operation with a timeout to prevent infinite loops
    static func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            
            // Wait for all tasks to complete to avoid issues
            do {
                for try await _ in group {}
            } catch {
                // Ignore cancellation errors
            }
            
            return result
        }
    }
    
    /// Wait for an async operation to complete with a timeout
    static func waitForAsyncOperation(
        testCase: XCTestCase,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: @escaping () async throws -> Void
    ) {
        let expectation = XCTestExpectation(description: "Async operation")
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)", file: file, line: line)
            }
        }
        
        testCase.wait(for: [expectation], timeout: timeout)
    }
    
    /// Wait for a condition to be true with a timeout
    static func waitForCondition(
        testCase: XCTestCase,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) {
        let expectation = XCTestExpectation(description: "Condition to be true")
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        testCase.wait(for: [expectation], timeout: timeout)
        timer.invalidate()
    }
    
    // MARK: - Mock Configuration Helpers
    
    /// Configure a MockAIModel for success
    static func configureMockAIModelSuccess(
        _ mockModel: MockAIModel,
        response: ChatMessage? = nil
    ) {
        let defaultResponse = response ?? createTestChatMessage(
            role: .assistant,
            content: "Mock response"
        )
        mockModel.configureSuccessResponse(defaultResponse)
    }
    
    /// Configure a MockAIModel for error
    static func configureMockAIModelError(
        _ mockModel: MockAIModel,
        error: Error? = nil
    ) {
        let defaultError = error ?? AIModelError.invalidResponse
        mockModel.configureError(defaultError)
    }
    
    /// Configure a MockAITool for success
    static func configureMockAIToolSuccess(
        _ mockTool: inout MockAITool,
        result: String? = nil
    ) {
        let defaultResult = result ?? "Mock tool result"
        mockTool.configureSuccessResult(defaultResult)
    }
    
    /// Configure a MockAITool for error
    static func configureMockAIToolError(
        _ mockTool: inout MockAITool,
        error: Error? = nil
    ) {
        let defaultError = error ?? ToolError.executionFailed("Mock error")
        mockTool.configureError(defaultError)
    }
    
    /// Configure a MockKeychainHelper for success
    static func configureMockKeychainSuccess(
        _ mockKeychain: MockKeychainHelper,
        storedValue: String? = nil
    ) {
        if let value = storedValue {
            mockKeychain.setStoredValue(value, forKey: "test_key")
        }
    }
    
    /// Configure a MockKeychainHelper for error
    static func configureMockKeychainError(
        _ mockKeychain: MockKeychainHelper,
        error: Error? = nil
    ) {
        let defaultError = error ?? NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        mockKeychain.configureError(defaultError)
    }
    
    // MARK: - Test Data Cleanup
    
    /// Clean up test data from KeychainHelper
    /// Note: This function is disabled to avoid triggering biometric prompts during testing
    static func cleanupTestKeychainData() {
        // Note: We avoid using KeychainHelper.shared directly to prevent biometric prompts
        // Test cleanup is handled by individual test methods using mock keychains
    }
    
    /// Clean up test data from ToolRegistry
    @MainActor
    static func cleanupTestToolRegistryData() {
        let registry = ToolRegistry.shared
        registry.unregister(toolName: "test_register_tool")
        registry.unregister(toolName: "test_unregister_tool")
        registry.unregister(toolName: "test_get_tool")
        registry.unregister(toolName: "test_tool_1")
        registry.unregister(toolName: "test_tool_2")
        registry.unregister(toolName: "test_execute_tool")
    }
    
    // MARK: - Performance Test Helpers
    
    /// Measure the time taken to execute a block of code
    static func measureTime(
        file: StaticString = #file,
        line: UInt = #line,
        operation: () throws -> Void
    ) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try operation()
        } catch {
            XCTFail("Operation failed: \(error)", file: file, line: line)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return timeElapsed
    }
    
    /// Measure the time taken to execute an async block of code
    static func measureAsyncTime(
        testCase: XCTestCase,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: @escaping () async throws -> Void
    ) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        let expectation = XCTestExpectation(description: "Async operation timing")
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)", file: file, line: line)
            }
        }
        
        testCase.wait(for: [expectation], timeout: timeout)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return timeElapsed
    }
    
    // MARK: - Random Test Data
    
    /// Generate a random string of specified length
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    /// Generate a random UUID string
    static func randomUUID() -> String {
        return UUID().uuidString
    }
    
    /// Generate a random date within the last year
    static func randomDate() -> Date {
        let now = Date()
        let oneYearAgo = now.addingTimeInterval(-365 * 24 * 60 * 60)
        let randomTimeInterval = TimeInterval.random(in: 0...(now.timeIntervalSince(oneYearAgo)))
        return oneYearAgo.addingTimeInterval(randomTimeInterval)
    }
    
    /// Generate a random IP address
    static func randomIPAddress() -> String {
        let octets = (0..<4).map { _ in Int.random(in: 0...255) }
        return octets.map(String.init).joined(separator: ".")
    }
    
    // MARK: - Test Environment Helpers
    
    /// Check if running in a test environment
    static var isRunningInTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    /// Get the current test method name
    static func currentTestName() -> String {
        return Thread.callStackSymbols[1]
    }
    
    /// Log test information
    static func logTestInfo(_ message: String) {
        if isRunningInTests {
            print("[TEST] \(message)")
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Wait for an async operation with a timeout
    func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) throws -> T {
        var result: T?
        var thrownError: Error?
        let expectation = XCTestExpectation(description: "Async operation")
        
        Task {
            do {
                result = try await operation()
                expectation.fulfill()
            } catch {
                thrownError = error
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        
        if let error = thrownError {
            throw error
        }
        
        guard let result = result else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No result returned"])
        }
        
        return result
    }
    
    /// Assert that an async operation throws a specific error
    func assertAsyncThrows<T>(
        _ expectedError: Error,
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) {
        let expectation = XCTestExpectation(description: "Async operation should throw")
        
        Task {
            do {
                let _ = try await operation()
                XCTFail("Expected operation to throw \(expectedError)")
            } catch {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Assert that an async operation completes successfully
    func assertAsyncSucceeds<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) -> T? {
        var result: T?
        let expectation = XCTestExpectation(description: "Async operation should succeed")
        
        Task {
            do {
                result = try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Expected operation to succeed, but it threw: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        return result
    }
}
