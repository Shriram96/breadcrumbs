//
//  AITool.swift
//  breadcrumbs
//
//  AI Tool Protocol - Interface for tools that AI models can invoke
//

import Foundation
import Combine

/// A sendable wrapper for tool parameter schemas
/// Represents JSON Schema in a type-safe, thread-safe manner
struct ToolParameterSchema: Sendable {
    let jsonSchema: [String: Any]

    init(_ schema: [String: Any]) {
        self.jsonSchema = schema
    }
}

/// Base protocol for tool input models
/// All tool inputs should conform to this for type safety
protocol ToolInput: Sendable {
    /// Convert to dictionary for JSON schema validation
    func toDictionary() -> [String: Any]
}

/// Base protocol for tool output models
/// All tool outputs should conform to this for structured responses
protocol ToolOutput: Sendable {
    /// Convert output to human-readable string for AI consumption
    func toFormattedString() -> String
}

/// Protocol that all tools must conform to for AI model integration
protocol AITool: Sendable {
    /// Unique identifier for the tool (must match function name in tool definition)
    var name: String { get }

    /// Human-readable description of what the tool does
    /// This helps the AI decide when to use this tool
    var description: String { get }

    /// JSON Schema defining the tool's parameters
    /// Returns a ToolParameterSchema wrapper containing the schema definition
    ///
    /// Example:
    /// ```swift
    /// var parametersSchema: ToolParameterSchema {
    ///     ToolParameterSchema([
    ///         "type": "object",
    ///         "properties": [
    ///             "query": [
    ///                 "type": "string",
    ///                 "description": "Search query"
    ///             ]
    ///         ],
    ///         "required": ["query"]
    ///     ])
    /// }
    /// ```
    var parametersSchema: ToolParameterSchema { get }

    /// Execute the tool with provided arguments
    /// - Parameter arguments: JSON-decoded arguments as a dictionary
    /// - Returns: String result that will be sent back to the AI model
    func execute(arguments: [String: Any]) async throws -> String
}

/// Default implementation for ToolInput (for Codable types)
extension ToolInput where Self: Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

/// Helper extension to convert AITool to OpenAI's ChatCompletionToolParam format
extension AITool {
    /// Convert this tool to a format compatible with OpenAI's function calling
    /// Returns a dictionary that can be used with MacPaw/OpenAI package
    var asOpenAIFunction: [String: Any] {
        return [
            "type": "function",
            "function": [
                "name": name,
                "description": description,
                "parameters": parametersSchema.jsonSchema
            ]
        ]
    }
}

/// Errors that can occur during tool execution
enum ToolError: LocalizedError {
    case invalidArguments(String)
    case executionFailed(String)
    case toolNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return "Invalid tool arguments: \(message)"
        case .executionFailed(let message):
            return "Tool execution failed: \(message)"
        case .toolNotFound(let name):
            return "Tool not found: \(name)"
        }
    }
}

/// Tool registry to manage available tools
@MainActor
class ToolRegistry: ObservableObject {
    @Published private(set) var tools: [String: AITool] = [:]

    nonisolated static let shared: ToolRegistry = {
        // Create instance on main actor
        return MainActor.assumeIsolated {
            ToolRegistry()
        }
    }()

    private init() {
        // Register default tools
        registerDefaultTools()
    }
    
    // Public initializer for testing
    init(forTesting: Bool) {
        // Don't register default tools for testing
    }

    /// Register a tool in the registry
    func register(_ tool: AITool) {
        tools[tool.name] = tool
    }

    /// Unregister a tool from the registry
    func unregister(toolName: String) {
        tools.removeValue(forKey: toolName)
    }

    /// Get a tool by name
    func getTool(named name: String) -> AITool? {
        return tools[name]
    }

    /// Get all registered tools as an array
    func getAllTools() -> [AITool] {
        return Array(tools.values)
    }

    /// Execute a tool by name with provided arguments
    func executeTool(name: String, arguments: [String: Any]) async throws -> String {
        guard let tool = tools[name] else {
            throw ToolError.toolNotFound(name)
        }
        return try await tool.execute(arguments: arguments)
    }

    private func registerDefaultTools() {
        // Register system diagnostic tools
        register(VPNDetectorTool())
    }
}
