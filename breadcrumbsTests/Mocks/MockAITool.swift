//
//  MockAITool.swift
//  breadcrumbsTests
//
//  Mock implementation of AITool for testing
//

@testable import breadcrumbs
import Combine
import Foundation

// MARK: - MockAITool

/// Mock implementation of AITool for unit testing
final class MockAITool: AITool, @unchecked Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        name: String = "mock_tool",
        description: String = "Mock tool for testing",
        parametersSchema: ToolParameterSchema = ToolParameterSchema([
            "type": "object",
            "properties": [
                "test_param": [
                    "type": "string",
                    "description": "Test parameter",
                ],
            ],
            "required": [],
        ])
    ) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
    }

    // MARK: Internal

    let name: String
    let description: String
    let parametersSchema: ToolParameterSchema

    // MARK: - Mock Configuration

    var shouldThrowError: Bool = false
    var mockError: Error = ToolError.executionFailed("Mock error")
    var mockResult: String = "Mock tool result"
    var executeCallCount: Int = 0
    var lastArguments: [String: Any]?

    // MARK: - AITool Implementation

    func execute(arguments: [String: Any]) async throws -> String {
        executeCallCount += 1
        lastArguments = arguments

        if shouldThrowError {
            throw mockError
        }

        return mockResult
    }

    // MARK: - Test Helpers

    func reset() {
        shouldThrowError = false
        mockError = ToolError.executionFailed("Mock error")
        mockResult = "Mock tool result"
        executeCallCount = 0
        lastArguments = nil
    }

    func configureSuccessResult(_ result: String) {
        shouldThrowError = false
        mockResult = result
    }

    func configureError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }
}

// MARK: - MockToolRegistry

/// Mock tool registry for testing
@MainActor
final class MockToolRegistry: ToolRegistry {
    // MARK: Lifecycle

    override init(forTesting: Bool) {
        super.init(forTesting: true)
    }

    // MARK: Internal

    var executeToolCallCount: Int = 0
    var lastExecuteToolName: String?
    var lastExecuteToolArguments: [String: Any]?
    var shouldThrowError: Bool = false
    var mockError: Error = ToolError.toolNotFound("Mock error")
    var mockResult: String = "Mock registry result"

    override func register(_ tool: AITool) {
        super.register(tool)
    }

    override func unregister(toolName: String) {
        super.unregister(toolName: toolName)
    }

    override func getTool(named name: String) -> AITool? {
        return super.getTool(named: name)
    }

    override func getAllTools() -> [AITool] {
        return super.getAllTools()
    }

    override func executeTool(name: String, arguments: [String: Any]) async throws -> String {
        executeToolCallCount += 1
        lastExecuteToolName = name
        lastExecuteToolArguments = arguments

        if shouldThrowError {
            throw mockError
        }

        guard let tool = tools[name] else {
            throw ToolError.toolNotFound(name)
        }

        return try await tool.execute(arguments: arguments)
    }

    func reset() {
        // Note: Cannot clear tools as it's not accessible for modification
        executeToolCallCount = 0
        lastExecuteToolName = nil
        lastExecuteToolArguments = nil
        shouldThrowError = false
        mockError = ToolError.toolNotFound("Mock error")
        mockResult = "Mock registry result"
    }
}
