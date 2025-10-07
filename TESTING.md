# 🧪 Testing Documentation

This document provides comprehensive information about the testing strategy, test structure, and testing guidelines for the Breadcrumbs project.

## 🎯 Testing Strategy

### Test Pyramid

Breadcrumbs follows a comprehensive testing strategy with multiple layers:

```
        /\
       /  \
      / UI \     ← UI Tests (End-to-end user workflows)
     /______\
    /        \
   /Integration\ ← Integration Tests (Component interactions)
  /______________\
 /                \
/    Unit Tests    \ ← Unit Tests (Individual components)
/__________________\
```

### Testing Levels

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions and workflows
3. **UI Tests**: Test complete user workflows and interface behavior
4. **Performance Tests**: Test system performance under load

## 📁 Test Structure

### Test Organization

```
breadcrumbsTests/
├── Integration/                    # Integration tests
│   └── AppIntegrationTests.swift  # Full app workflow tests
├── Mocks/                         # Mock implementations
│   ├── MockAIModel.swift         # AI model mock
│   ├── MockAITool.swift          # Tool mock
│   ├── MockAppCheckerTool.swift  # App checker mock
│   ├── MockDNSReachabilityTool.swift # DNS tool mock
│   └── MockKeychainHelper.swift  # Keychain mock
├── Models/                        # Model tests
│   ├── ChatMessageTests.swift    # Chat message tests
│   ├── ItemTests.swift           # SwiftData model tests
│   └── OpenAIModelTests.swift    # OpenAI model tests
├── Protocols/                     # Protocol tests
│   ├── AIModelTests.swift        # AI model protocol tests
│   └── AIToolTests.swift         # Tool protocol tests
├── TestHelpers/                   # Test utilities
│   └── TestUtilities.swift       # Common test utilities
├── Tools/                         # Tool tests
│   ├── AppCheckerToolTests.swift # App checker tests
│   ├── DNSReachabilityToolTests.swift # DNS tool tests
│   ├── SystemDiagnosticToolTests.swift # System diagnostic tests
│   └── VPNDetectorToolTests.swift # VPN detector tests
├── Utilities/                     # Utility tests
│   ├── KeychainHelperTests.swift # Keychain tests
│   └── LoggerTests.swift         # Logger tests
├── ViewModels/                    # ViewModel tests
│   └── ChatViewModelTests.swift  # Chat view model tests
└── README.md                      # Test documentation
```

## 🧪 Unit Testing

### Test Structure

Each unit test follows a consistent structure:

```swift
import XCTest
@testable import breadcrumbs

final class ComponentTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: ComponentUnderTest!
    private var mockDependency: MockDependency!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = ComponentUnderTest(dependency: mockDependency)
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testMethodName_GivenCondition_ShouldReturnExpectedResult() {
        // Given
        let input = "test input"
        let expectedOutput = "expected output"
        
        // When
        let result = sut.methodUnderTest(input)
        
        // Then
        XCTAssertEqual(result, expectedOutput)
    }
}
```

### Example Unit Tests

#### ChatViewModel Tests

```swift
final class ChatViewModelTests: XCTestCase {
    
    private var viewModel: ChatViewModel!
    private var mockAIModel: MockAIModel!
    private var mockToolRegistry: ToolRegistry!
    
    override func setUp() {
        super.setUp()
        mockAIModel = MockAIModel()
        mockToolRegistry = ToolRegistry(forTesting: true)
        viewModel = ChatViewModel(aiModel: mockAIModel, toolRegistry: mockToolRegistry)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAIModel = nil
        mockToolRegistry = nil
        super.tearDown()
    }
    
    func testSendMessage_GivenValidMessage_ShouldAddUserMessage() async {
        // Given
        let message = "Test message"
        let expectedResponse = ChatMessage(role: .assistant, content: "Test response")
        mockAIModel.mockResponse = expectedResponse
        
        // When
        await viewModel.sendMessage(message)
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 3) // System + user + assistant
        XCTAssertEqual(viewModel.messages[1].role, .user)
        XCTAssertEqual(viewModel.messages[1].content, message)
        XCTAssertEqual(viewModel.messages[2].role, .assistant)
        XCTAssertEqual(viewModel.messages[2].content, "Test response")
    }
    
    func testSendMessage_GivenToolCalls_ShouldExecuteTools() async {
        // Given
        let message = "Check my VPN status"
        let toolCall = ToolCall(id: "call_1", name: "vpn_detector", arguments: "{}")
        let responseWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall]
        )
        mockAIModel.mockResponse = responseWithTools
        
        // When
        await viewModel.sendMessage(message)
        
        // Then
        XCTAssertTrue(mockAIModel.sendMessageCalled)
        XCTAssertEqual(viewModel.messages.count, 4) // System + user + assistant + tool result
    }
    
    func testClearChat_ShouldRemoveAllMessagesExceptSystem() {
        // Given
        viewModel.messages = [
            ChatMessage(role: .system, content: "System prompt"),
            ChatMessage(role: .user, content: "User message"),
            ChatMessage(role: .assistant, content: "Assistant response")
        ]
        
        // When
        viewModel.clearChat()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .system)
    }
}
```

#### Tool Tests

```swift
final class VPNDetectorToolTests: XCTestCase {
    
    private var tool: VPNDetectorTool!
    
    override func setUp() {
        super.setUp()
        tool = VPNDetectorTool()
    }
    
    override func tearDown() {
        tool = nil
        super.tearDown()
    }
    
    func testExecute_GivenNoArguments_ShouldReturnVPNStatus() async throws {
        // Given
        let arguments: [String: Any] = [:]
        
        // When
        let result = try await tool.execute(arguments: arguments)
        
        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("VPN Connection Status"))
    }
    
    func testExecute_GivenSpecificInterface_ShouldCheckInterface() async throws {
        // Given
        let arguments: [String: Any] = ["interface_name": "utun0"]
        
        // When
        let result = try await tool.execute(arguments: arguments)
        
        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("VPN Connection Status"))
    }
    
    func testParametersSchema_ShouldHaveCorrectStructure() {
        // When
        let schema = tool.parametersSchema
        
        // Then
        let jsonSchema = schema.jsonSchema
        XCTAssertEqual(jsonSchema["type"] as? String, "object")
        
        let properties = jsonSchema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)
        
        let interfaceName = properties?["interface_name"] as? [String: Any]
        XCTAssertEqual(interfaceName?["type"] as? String, "string")
    }
}
```

## 🔗 Integration Testing

### Integration Test Structure

Integration tests verify that components work together correctly:

```swift
final class AppIntegrationTests: XCTestCase {
    
    func testFullChatFlow_WithVPNDetection() async throws {
        // Given
        let apiKey = "test-api-key"
        let model = OpenAIModel(apiToken: apiKey)
        let viewModel = ChatViewModel(aiModel: model)
        
        // When
        await viewModel.sendMessage("Check my VPN status")
        
        // Then
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertTrue(viewModel.messages.contains { $0.role == .assistant })
        
        // Verify tool was used
        let assistantMessages = viewModel.messages.filter { $0.role == .assistant }
        XCTAssertTrue(assistantMessages.contains { $0.toolCalls != nil })
    }
    
    func testServerAPI_WithChatEndpoint() async throws {
        // Given
        let server = VaporServer(
            aiModel: MockAIModel(),
            toolRegistry: ToolRegistry(forTesting: true),
            apiKey: "test-key"
        )
        
        // When
        try await server.start()
        defer { server.stop() }
        
        // Then
        // Test API endpoints
        let healthResponse = try await testHealthEndpoint()
        XCTAssertEqual(healthResponse.status, "healthy")
        
        let toolsResponse = try await testToolsEndpoint()
        XCTAssertFalse(toolsResponse.tools.isEmpty)
        
        let chatResponse = try await testChatEndpoint()
        XCTAssertFalse(chatResponse.response.isEmpty)
    }
}
```

## 🎨 UI Testing

### UI Test Structure

UI tests verify complete user workflows:

```swift
final class breadcrumbsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCompleteChatWorkflow() throws {
        // Given: App is launched
        
        // When: User enters a message
        let messageField = app.textFields["Ask about your system..."]
        XCTAssertTrue(messageField.exists)
        messageField.tap()
        messageField.typeText("Check my VPN status")
        
        // And: User sends the message
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        // Then: Response should appear
        let responseText = app.staticTexts.containing(NSPredicate(format: "value CONTAINS 'VPN'"))
        XCTAssertTrue(responseText.element.waitForExistence(timeout: 10))
    }
    
    func testSettingsConfiguration() throws {
        // Given: App is launched
        
        // When: User opens settings
        let settingsButton = app.buttons["Settings"]
        settingsButton.tap()
        
        // Then: Settings view should appear
        let settingsView = app.otherElements["SettingsView"]
        XCTAssertTrue(settingsView.exists)
        
        // And: User can configure API key
        let apiKeyField = app.secureTextFields["sk-..."]
        XCTAssertTrue(apiKeyField.exists)
        apiKeyField.tap()
        apiKeyField.typeText("test-api-key")
        
        // And: User can save settings
        let saveButton = app.buttons["Save"]
        saveButton.tap()
        
        // Then: Settings should close
        XCTAssertFalse(settingsView.exists)
    }
}
```

## 🎭 Mock Implementations

### Mock AI Model

```swift
final class MockAIModel: AIModel {
    
    // MARK: - Properties
    var mockResponse: ChatMessage?
    var mockError: Error?
    var sendMessageCalled = false
    var lastMessages: [ChatMessage]?
    var lastTools: [AITool]?
    
    let providerId = "mock"
    let displayName = "Mock Model"
    let supportsTools = true
    
    // MARK: - AIModel Protocol
    func sendMessage(messages: [ChatMessage], tools: [AITool]?) async throws -> ChatMessage {
        sendMessageCalled = true
        lastMessages = messages
        lastTools = tools
        
        if let error = mockError {
            throw error
        }
        
        return mockResponse ?? ChatMessage(
            role: .assistant,
            content: "Mock response"
        )
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResponse = nil
        mockError = nil
        sendMessageCalled = false
        lastMessages = nil
        lastTools = nil
    }
}
```

### Mock Tool

```swift
final class MockAITool: AITool {
    
    // MARK: - Properties
    var mockResult: String = "Mock tool result"
    var mockError: Error?
    var executeCalled = false
    var lastArguments: [String: Any]?
    
    let name = "mock_tool"
    let description = "Mock tool for testing"
    
    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "test_param": [
                    "type": "string",
                    "description": "Test parameter"
                ]
            ]
        ])
    }
    
    // MARK: - AITool Protocol
    func execute(arguments: [String: Any]) async throws -> String {
        executeCalled = true
        lastArguments = arguments
        
        if let error = mockError {
            throw error
        }
        
        return mockResult
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResult = "Mock tool result"
        mockError = nil
        executeCalled = false
        lastArguments = nil
    }
}
```

### Mock Keychain Helper

```swift
final class MockKeychainHelper: KeychainProtocol {
    
    // MARK: - Properties
    var mockValues: [String: String] = [:]
    var mockBiometricAvailable = false
    var mockBiometricType = "Touch ID"
    var saveCalled = false
    var getCalled = false
    var deleteCalled = false
    
    // MARK: - KeychainProtocol
    func save(_ value: String, forKey key: String, requireBiometric: Bool) -> Bool {
        saveCalled = true
        mockValues[key] = value
        return true
    }
    
    func get(forKey key: String, prompt: String?) -> String? {
        getCalled = true
        return mockValues[key]
    }
    
    func delete(forKey key: String) -> Bool {
        deleteCalled = true
        mockValues.removeValue(forKey: key)
        return true
    }
    
    func update(_ value: String, forKey key: String, requireBiometric: Bool) -> Bool {
        mockValues[key] = value
        return true
    }
    
    func exists(forKey key: String) -> Bool {
        return mockValues[key] != nil
    }
    
    func isBiometricAuthenticationAvailable() -> Bool {
        return mockBiometricAvailable
    }
    
    func getBiometricType() -> String {
        return mockBiometricType
    }
    
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(true, nil)
        }
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockValues.removeAll()
        mockBiometricAvailable = false
        mockBiometricType = "Touch ID"
        saveCalled = false
        getCalled = false
        deleteCalled = false
    }
}
```

## 🛠 Test Utilities

### Test Utilities

```swift
final class TestUtilities {
    
    // MARK: - Test Data
    static func createMockChatMessage(
        role: MessageRole = .user,
        content: String = "Test message",
        toolCalls: [ToolCall]? = nil
    ) -> ChatMessage {
        return ChatMessage(
            role: role,
            content: content,
            toolCalls: toolCalls
        )
    }
    
    static func createMockToolCall(
        id: String = "call_1",
        name: String = "test_tool",
        arguments: String = "{}"
    ) -> ToolCall {
        return ToolCall(id: id, name: name, arguments: arguments)
    }
    
    // MARK: - Async Testing
    static func waitForCondition(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        return false
    }
    
    // MARK: - Mock Data
    static let mockVPNResponse = """
    VPN Connection Status:
    - Connected: YES
    - VPN Type: IKEv2
    - Interface: utun0
    - IP Address: 10.0.0.1
    - Connected Since: 2:30 PM
    """
    
    static let mockDNSResponse = """
    DNS Reachability Check for google.com:
    - Reachable: YES
    - Response Time: 0.045s
    - DNS Records Found (1):
      • A: 142.250.191.14 (TTL: 300s)
    """
}
```

## 🚀 Running Tests

### Command Line

```bash
# Run all tests
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS'

# Run specific test class
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsTests/ChatViewModelTests

# Run specific test method
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsTests/ChatViewModelTests/testSendMessage_GivenValidMessage_ShouldAddUserMessage

# Run UI tests
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsUITests
```

### Xcode

1. **Select Test Target**: Choose `breadcrumbsTests` or `breadcrumbsUITests`
2. **Run Tests**: Press `Cmd+U` or click the play button
3. **Run Specific Tests**: Click the diamond icon next to individual tests
4. **View Results**: Check the Test Navigator for results

### Test Coverage

```bash
# Generate test coverage report
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -enableCodeCoverage YES

# View coverage in Xcode
# Product → Show Code Coverage
```

## 📊 Test Metrics

### Coverage Targets

- **Overall Coverage**: > 80%
- **Critical Paths**: > 95%
- **New Code**: > 90%

### Performance Targets

- **Unit Tests**: < 1 second per test
- **Integration Tests**: < 5 seconds per test
- **UI Tests**: < 30 seconds per test

### Quality Metrics

- **Test Reliability**: > 99% pass rate
- **Test Maintainability**: Clear, readable test code
- **Test Coverage**: Comprehensive edge case coverage

## 🔧 Test Configuration

### Test Environment

```swift
// Test configuration
#if UNIT_TESTS
// Test-specific code
let mockAPIKey = "test-api-key"
#else
// Production code
let apiKey = KeychainHelper.shared.get(forKey: "api_key")
#endif
```

### Test Data Management

```swift
// Test data setup
final class TestDataManager {
    static func setupTestEnvironment() {
        // Configure test environment
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Setup test keychain
        let keychain = MockKeychainHelper()
        keychain.mockValues["test_key"] = "test_value"
    }
    
    static func cleanupTestEnvironment() {
        // Cleanup test data
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
```

## 🐛 Debugging Tests

### Test Debugging

```swift
// Add breakpoints in tests
func testMethod() {
    // Set breakpoint here
    let result = sut.methodUnderTest()
    XCTAssertEqual(result, expectedValue)
}

// Use print statements for debugging
func testMethod() {
    let result = sut.methodUnderTest()
    print("Result: \(result)")
    XCTAssertEqual(result, expectedValue)
}
```

### Test Logging

```swift
// Enable test logging
func testMethod() {
    Logger.tools("Starting test: \(#function)")
    
    let result = sut.methodUnderTest()
    
    Logger.tools("Test result: \(result)")
    XCTAssertEqual(result, expectedValue)
}
```

## 📈 Continuous Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Run tests
      run: xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS'
    
    - name: Generate coverage report
      run: xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -enableCodeCoverage YES
```

### Test Automation

```bash
#!/bin/bash
# scripts/run-tests.sh

set -e

echo "Running Breadcrumbs tests..."

# Run unit tests
echo "Running unit tests..."
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsTests

# Run integration tests
echo "Running integration tests..."
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsTests/AppIntegrationTests

# Run UI tests
echo "Running UI tests..."
xcodebuild test -project breadcrumbs.xcodeproj -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsUITests

echo "All tests completed successfully!"
```

## 🎯 Best Practices

### Test Naming

```swift
// ✅ Good: Descriptive test names
func testSendMessage_GivenValidMessage_ShouldAddUserMessage()
func testVPNDetector_GivenConnectedVPN_ShouldReturnConnectedStatus()
func testKeychainHelper_GivenBiometricAuth_ShouldStoreSecurely()

// ❌ Bad: Vague test names
func testSendMessage()
func testVPN()
func testKeychain()
```

### Test Organization

```swift
// ✅ Good: Grouped by functionality
final class ChatViewModelTests: XCTestCase {
    
    // MARK: - Send Message Tests
    func testSendMessage_GivenValidMessage_ShouldAddUserMessage() { }
    func testSendMessage_GivenEmptyMessage_ShouldNotSend() { }
    
    // MARK: - Tool Execution Tests
    func testSendMessage_GivenToolCalls_ShouldExecuteTools() { }
    func testSendMessage_GivenToolError_ShouldHandleError() { }
    
    // MARK: - Chat Management Tests
    func testClearChat_ShouldRemoveAllMessagesExceptSystem() { }
}
```

### Test Data

```swift
// ✅ Good: Use test utilities
func testMethod() {
    let message = TestUtilities.createMockChatMessage()
    let result = sut.processMessage(message)
    XCTAssertEqual(result, expectedResult)
}

// ❌ Bad: Hardcoded test data
func testMethod() {
    let message = ChatMessage(role: .user, content: "test", timestamp: Date(), id: UUID())
    let result = sut.processMessage(message)
    XCTAssertEqual(result, "expected")
}
```

---

This testing documentation provides comprehensive guidance for maintaining high-quality tests in the Breadcrumbs project. For additional help or examples, refer to the other documentation files or create an issue on GitHub.
