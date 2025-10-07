//
//  AIToolTests.swift
//  breadcrumbsTests
//
//  Unit tests for AITool protocol and related structures
//

@testable import breadcrumbs
import XCTest

final class AIToolTests: XCTestCase {
    // MARK: - ToolParameterSchema Tests

    func testToolParameterSchemaInitialization() {
        // Given
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "param1": [
                    "type": "string",
                    "description": "First parameter",
                ],
            ],
            "required": ["param1"],
        ]

        // When
        let parameterSchema = ToolParameterSchema(schema)

        // Then
        XCTAssertEqual(parameterSchema.jsonSchema["type"] as? String, "object")
        XCTAssertNotNil(parameterSchema.jsonSchema["properties"])
        XCTAssertNotNil(parameterSchema.jsonSchema["required"])
    }

    func testToolParameterSchemaEmptySchema() {
        // Given
        let emptySchema = [String: Any]()

        // When
        let parameterSchema = ToolParameterSchema(emptySchema)

        // Then
        XCTAssertTrue(parameterSchema.jsonSchema.isEmpty)
    }

    // MARK: - ToolInput Protocol Tests

    func testToolInputConformance() {
        // Given
        struct TestToolInput: ToolInput {
            let param1: String
            let param2: Int

            func toDictionary() -> [String: Any] {
                return [
                    "param1": param1,
                    "param2": param2,
                ]
            }
        }

        let input = TestToolInput(param1: "test", param2: 42)

        // When
        let dictionary = input.toDictionary()

        // Then
        XCTAssertEqual(dictionary["param1"] as? String, "test")
        XCTAssertEqual(dictionary["param2"] as? Int, 42)
    }

    func testToolInputCodableExtension() {
        // Given
        struct CodableToolInput: ToolInput, Codable {
            let param1: String
            let param2: Int
        }

        let input = CodableToolInput(param1: "test", param2: 42)

        // When
        let dictionary = input.toDictionary()

        // Then
        XCTAssertEqual(dictionary["param1"] as? String, "test")
        XCTAssertEqual(dictionary["param2"] as? Int, 42)
    }

    // MARK: - ToolOutput Protocol Tests

    func testToolOutputConformance() {
        // Given
        struct TestToolOutput: ToolOutput {
            let result: String
            let success: Bool

            func toFormattedString() -> String {
                return "Result: \(result), Success: \(success)"
            }
        }

        let output = TestToolOutput(result: "Operation completed", success: true)

        // When
        let formattedString = output.toFormattedString()

        // Then
        XCTAssertEqual(formattedString, "Result: Operation completed, Success: true")
    }

    // MARK: - AITool Protocol Tests

    func testAIToolConformance() {
        // Given
        struct TestAITool: AITool {
            let name: String = "test_tool"
            let description: String = "A test tool for unit testing"
            let parametersSchema: ToolParameterSchema = .init([
                "type": "object",
                "properties": [
                    "param1": [
                        "type": "string",
                        "description": "Test parameter",
                    ],
                ],
                "required": ["param1"],
            ])

            func execute(arguments: [String: Any]) async throws -> String {
                guard let param1 = arguments["param1"] as? String else {
                    throw ToolError.invalidArguments("param1 is required")
                }

                return "Executed with param1: \(param1)"
            }
        }

        let tool = TestAITool()

        // Then
        XCTAssertEqual(tool.name, "test_tool")
        XCTAssertEqual(tool.description, "A test tool for unit testing")
        XCTAssertNotNil(tool.parametersSchema)
    }

    func testAIToolExecute() async throws {
        // Given
        struct TestAITool: AITool {
            let name: String = "test_tool"
            let description: String = "A test tool"
            let parametersSchema: ToolParameterSchema = .init([:])

            func execute(arguments: [String: Any]) async throws -> String {
                return "Test result"
            }
        }

        let tool = TestAITool()
        let arguments = [String: Any]()

        // When
        let result = try await tool.execute(arguments: arguments)

        // Then
        XCTAssertEqual(result, "Test result")
    }

    // MARK: - AITool Extension Tests

    func testAsOpenAIFunction() {
        // Given
        let tool = MockAITool(
            name: "test_tool",
            description: "Test tool description",
            parametersSchema: ToolParameterSchema([
                "type": "object",
                "properties": [
                    "param1": [
                        "type": "string",
                        "description": "Test parameter",
                    ],
                ],
            ])
        )

        // When
        let openAIFunction = tool.asOpenAIFunction

        // Then
        XCTAssertEqual(openAIFunction["type"] as? String, "function")
        XCTAssertNotNil(openAIFunction["function"])

        let function = openAIFunction["function"] as? [String: Any]
        XCTAssertEqual(function?["name"] as? String, "test_tool")
        XCTAssertEqual(function?["description"] as? String, "Test tool description")
        XCTAssertNotNil(function?["parameters"])
    }

    // MARK: - ToolError Tests

    func testToolErrorInvalidArguments() {
        // Given
        let error = ToolError.invalidArguments("Test error message")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertEqual(description, "Invalid tool arguments: Test error message")
    }

    func testToolErrorExecutionFailed() {
        // Given
        let error = ToolError.executionFailed("Test execution error")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertEqual(description, "Tool execution failed: Test execution error")
    }

    func testToolErrorToolNotFound() {
        // Given
        let error = ToolError.toolNotFound("nonexistent_tool")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertEqual(description, "Tool not found: nonexistent_tool")
    }

    // MARK: - ToolRegistry Tests

    @MainActor
    func testToolRegistryInitialization() {
        // Given & When
        let registry = ToolRegistry.shared

        // Then
        XCTAssertNotNil(registry)
        XCTAssertFalse(registry.getAllTools().isEmpty) // Should have default tools
    }

    @MainActor
    func testToolRegistryRegister() {
        // Given
        let registry = ToolRegistry.shared
        let tool = MockAITool(name: "test_register_tool")

        // When
        registry.register(tool)

        // Then
        XCTAssertNotNil(registry.getTool(named: "test_register_tool"))
        XCTAssertTrue(registry.getAllTools().contains { $0.name == "test_register_tool" })

        // Clean up
        registry.unregister(toolName: "test_register_tool")
    }

    @MainActor
    func testToolRegistryUnregister() {
        // Given
        let registry = ToolRegistry.shared
        let tool = MockAITool(name: "test_unregister_tool")
        registry.register(tool)

        // When
        registry.unregister(toolName: "test_unregister_tool")

        // Then
        XCTAssertNil(registry.getTool(named: "test_unregister_tool"))
        XCTAssertFalse(registry.getAllTools().contains { $0.name == "test_unregister_tool" })
    }

    @MainActor
    func testToolRegistryGetTool() {
        // Given
        let registry = ToolRegistry.shared
        let tool = MockAITool(name: "test_get_tool")
        registry.register(tool)

        // When
        let retrievedTool = registry.getTool(named: "test_get_tool")

        // Then
        XCTAssertNotNil(retrievedTool)
        XCTAssertEqual(retrievedTool?.name, "test_get_tool")

        // Clean up
        registry.unregister(toolName: "test_get_tool")
    }

    @MainActor
    func testToolRegistryGetAllTools() {
        // Given
        let registry = ToolRegistry.shared
        let tool1 = MockAITool(name: "test_tool_1")
        let tool2 = MockAITool(name: "test_tool_2")
        registry.register(tool1)
        registry.register(tool2)

        // When
        let allTools = registry.getAllTools()

        // Then
        XCTAssertTrue(allTools.contains { $0.name == "test_tool_1" })
        XCTAssertTrue(allTools.contains { $0.name == "test_tool_2" })

        // Clean up
        registry.unregister(toolName: "test_tool_1")
        registry.unregister(toolName: "test_tool_2")
    }

    @MainActor
    func testToolRegistryExecuteTool() async throws {
        // Given
        let registry = ToolRegistry.shared
        let tool = MockAITool(name: "test_execute_tool")
        registry.register(tool)
        let arguments: [String: Any] = ["param1": "value1"]

        // When
        let result = try await registry.executeTool(name: "test_execute_tool", arguments: arguments)

        // Then
        XCTAssertEqual(result, "Mock tool result")

        // Clean up
        registry.unregister(toolName: "test_execute_tool")
    }

    @MainActor
    func testToolRegistryExecuteToolNotFound() async {
        // Given
        let registry = ToolRegistry.shared
        let arguments = [String: Any]()

        // When & Then
        do {
            _ = try await registry.executeTool(name: "nonexistent_tool", arguments: arguments)
            XCTFail("Should have thrown an error")
        } catch let ToolError.toolNotFound(toolName) {
            XCTAssertEqual(toolName, "nonexistent_tool")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Sendable Conformance Tests

    func testToolParameterSchemaSendable() {
        // This test verifies that ToolParameterSchema can be used in concurrent contexts
        let schema = ToolParameterSchema(["type": "object"])

        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = schema
        }

        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }

    func testToolErrorSendable() {
        // This test verifies that ToolError can be used in concurrent contexts
        let error = ToolError.invalidArguments("test")

        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = error
        }

        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }

    // MARK: - Edge Cases Tests

    func testToolParameterSchemaWithComplexSchema() {
        // Given
        let complexSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "string_param": [
                    "type": "string",
                    "description": "A string parameter",
                    "minLength": 1,
                    "maxLength": 100,
                ],
                "number_param": [
                    "type": "number",
                    "description": "A number parameter",
                    "minimum": 0,
                    "maximum": 1000,
                ],
                "boolean_param": [
                    "type": "boolean",
                    "description": "A boolean parameter",
                ],
                "array_param": [
                    "type": "array",
                    "description": "An array parameter",
                    "items": [
                        "type": "string",
                    ],
                ],
            ],
            "required": ["string_param", "number_param"],
            "additionalProperties": false,
        ]

        // When
        let parameterSchema = ToolParameterSchema(complexSchema)

        // Then
        XCTAssertEqual(parameterSchema.jsonSchema["type"] as? String, "object")
        XCTAssertNotNil(parameterSchema.jsonSchema["properties"])
        XCTAssertNotNil(parameterSchema.jsonSchema["required"])
        XCTAssertEqual(parameterSchema.jsonSchema["additionalProperties"] as? Bool, false)
    }

    func testToolExecuteWithEmptyArguments() async throws {
        // Given
        struct TestAITool: AITool {
            let name: String = "test_empty_args_tool"
            let description: String = "Test tool"
            let parametersSchema: ToolParameterSchema = .init([:])

            func execute(arguments: [String: Any]) async throws -> String {
                return "Executed with \(arguments.count) arguments"
            }
        }

        let tool = TestAITool()
        let emptyArguments = [String: Any]()

        // When
        let result = try await tool.execute(arguments: emptyArguments)

        // Then
        XCTAssertEqual(result, "Executed with 0 arguments")
    }

    func testToolExecuteWithNilValues() async throws {
        // Given
        struct TestAITool: AITool {
            let name: String = "test_nil_values_tool"
            let description: String = "Test tool"
            let parametersSchema: ToolParameterSchema = .init([:])

            func execute(arguments: [String: Any]) async throws -> String {
                let nilValue = arguments["nil_param"] as? String
                return "Nil value: \(nilValue ?? "not found")"
            }
        }

        let tool = TestAITool()
        let arguments: [String: Any] = ["nil_param": NSNull()]

        // When
        let result = try await tool.execute(arguments: arguments)

        // Then
        XCTAssertEqual(result, "Nil value: not found")
    }
}
