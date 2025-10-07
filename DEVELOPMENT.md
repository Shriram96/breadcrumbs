# 👨‍💻 Development Guide

This guide provides comprehensive information for developers working on the Breadcrumbs project, including coding standards, development workflows, and contribution guidelines.

## 🏗️ Development Environment Setup

### Prerequisites

- **macOS**: 15.0 (Sequoia) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Git**: Latest version
- **Command Line Tools**: `xcode-select --install`

### Initial Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/breadcrumbs.git
   cd breadcrumbs
   ```

2. **Open in Xcode**:
   ```bash
   open breadcrumbs.xcodeproj
   ```

3. **Install Dependencies**:
   - Dependencies are managed via Swift Package Manager
   - Xcode will automatically resolve packages on first build

4. **Configure Development Environment**:
   ```bash
   # Set up git hooks (optional)
   cp scripts/pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit
   ```

## 📁 Project Structure

```
breadcrumbs/
├── breadcrumbs/                    # Main application target
│   ├── Models/                     # Data models and structures
│   │   └── OpenAIModel.swift      # OpenAI API integration
│   ├── Protocols/                  # Protocol definitions
│   │   ├── AIModel.swift          # AI model protocol
│   │   ├── AITool.swift           # Tool protocol
│   │   └── KeychainProtocol.swift # Keychain protocol
│   ├── Services/                   # Business logic services
│   │   ├── ServiceManager.swift   # HTTP server management
│   │   └── VaporServer.swift      # Vapor HTTP server
│   ├── Tools/                      # Diagnostic tools
│   │   ├── VPNDetectorTool.swift  # VPN detection
│   │   ├── DNSReachabilityTool.swift # DNS testing
│   │   ├── AppCheckerTool.swift   # App information
│   │   └── SystemDiagnosticTool.swift # System diagnostics
│   ├── Utilities/                  # Helper utilities
│   │   ├── KeychainHelper.swift   # Keychain operations
│   │   └── Logger.swift           # Logging system
│   ├── ViewModels/                 # SwiftUI view models
│   │   └── ChatViewModel.swift    # Chat interface logic
│   ├── Views/                      # SwiftUI views
│   │   ├── ContentView.swift      # Main app view
│   │   ├── ChatView.swift         # Chat interface
│   │   ├── SettingsView.swift     # Settings interface
│   │   └── ServerSettingsView.swift # Server settings
│   ├── Assets.xcassets/           # App assets
│   ├── breadcrumbs.entitlements   # App entitlements
│   ├── breadcrumbsApp.swift       # App entry point
│   ├── ContentView.swift          # Main content view
│   ├── Item.swift                 # SwiftData model
│   ├── Info.plist                 # App configuration
│   └── ServerMode.swift           # Command-line server
├── breadcrumbsTests/              # Unit tests
│   ├── Integration/               # Integration tests
│   ├── Mocks/                     # Mock implementations
│   ├── Models/                    # Model tests
│   ├── Protocols/                 # Protocol tests
│   ├── TestHelpers/               # Test utilities
│   ├── Tools/                     # Tool tests
│   ├── Utilities/                 # Utility tests
│   ├── ViewModels/                # ViewModel tests
│   └── README.md                  # Test documentation
├── breadcrumbsUITests/            # UI tests
├── docs/                          # Documentation
├── scripts/                       # Build and utility scripts
├── Package.swift                  # Swift Package Manager config
└── breadcrumbs.xcodeproj/         # Xcode project file
```

## 🎯 Coding Standards

### Swift Style Guide

Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

#### Naming Conventions

```swift
// Types: PascalCase
struct ChatMessage { }
class OpenAIModel { }
protocol AITool { }

// Functions and variables: camelCase
func sendMessage() { }
var isProcessing: Bool = false

// Constants: camelCase
let maxRetryCount = 3

// Private properties: underscore prefix
private let _internalState: String
```

#### Code Organization

```swift
// 1. Imports
import Foundation
import SwiftUI

// 2. Type declaration
final class ChatViewModel: ObservableObject {
    
    // 3. MARK: - Properties
    @Published var messages: [ChatMessage] = []
    private let aiModel: AIModel
    
    // 4. MARK: - Initialization
    init(aiModel: AIModel) {
        self.aiModel = aiModel
    }
    
    // 5. MARK: - Public Methods
    func sendMessage(_ content: String) async {
        // Implementation
    }
    
    // 6. MARK: - Private Methods
    private func handleToolCalls() async {
        // Implementation
    }
}
```

#### Documentation

Use Swift DocC for all public APIs:

```swift
/// Sends a message to the AI model and handles the response
/// - Parameter content: The message content to send
/// - Returns: The AI's response message
/// - Throws: `AIModelError` if the request fails
func sendMessage(_ content: String) async throws -> ChatMessage {
    // Implementation
}
```

### Error Handling

Use proper error types and localized descriptions:

```swift
enum AIModelError: LocalizedError {
    case invalidResponse
    case apiKeyMissing
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI model"
        case .apiKeyMissing:
            return "API key is missing"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Async/Await Patterns

Use modern Swift concurrency:

```swift
// ✅ Good: Proper async/await usage
func executeTool() async throws -> String {
    let result = try await performOperation()
    return result
}

// ✅ Good: Task management
func startOperation() {
    Task {
        do {
            let result = try await executeTool()
            await MainActor.run {
                self.result = result
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
}

// ❌ Bad: Blocking operations
func executeTool() -> String {
    return performOperation() // Blocks thread
}
```

## 🧪 Testing Guidelines

### Test Structure

Organize tests by feature and layer:

```
breadcrumbsTests/
├── Models/
│   ├── ChatMessageTests.swift
│   └── OpenAIModelTests.swift
├── Protocols/
│   ├── AIModelTests.swift
│   └── AIToolTests.swift
├── Tools/
│   ├── VPNDetectorToolTests.swift
│   └── DNSReachabilityToolTests.swift
├── ViewModels/
│   └── ChatViewModelTests.swift
└── Integration/
    └── AppIntegrationTests.swift
```

### Unit Testing

```swift
import XCTest
@testable import breadcrumbs

final class ChatViewModelTests: XCTestCase {
    
    private var viewModel: ChatViewModel!
    private var mockAIModel: MockAIModel!
    
    override func setUp() {
        super.setUp()
        mockAIModel = MockAIModel()
        viewModel = ChatViewModel(aiModel: mockAIModel)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAIModel = nil
        super.tearDown()
    }
    
    func testSendMessage() async {
        // Given
        let message = "Test message"
        let expectedResponse = ChatMessage(role: .assistant, content: "Test response")
        mockAIModel.mockResponse = expectedResponse
        
        // When
        await viewModel.sendMessage(message)
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 2) // System + user + assistant
        XCTAssertEqual(viewModel.messages.last?.content, "Test response")
    }
}
```

### Mock Implementations

```swift
final class MockAIModel: AIModel {
    var mockResponse: ChatMessage?
    var mockError: Error?
    
    let providerId = "mock"
    let displayName = "Mock Model"
    let supportsTools = true
    
    func sendMessage(messages: [ChatMessage], tools: [AITool]?) async throws -> ChatMessage {
        if let error = mockError {
            throw error
        }
        return mockResponse ?? ChatMessage(role: .assistant, content: "Mock response")
    }
}
```

### Integration Testing

```swift
final class AppIntegrationTests: XCTestCase {
    
    func testFullChatFlow() async throws {
        // Given
        let apiKey = "test-api-key"
        let model = OpenAIModel(apiToken: apiKey)
        let viewModel = ChatViewModel(aiModel: model)
        
        // When
        await viewModel.sendMessage("Check my VPN status")
        
        // Then
        // Verify tool execution and response
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertTrue(viewModel.messages.contains { $0.role == .assistant })
    }
}
```

## 🔧 Development Workflow

### Git Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-diagnostic-tool
   ```

2. **Make Changes**:
   - Write code following style guidelines
   - Add tests for new functionality
   - Update documentation

3. **Test Changes**:
   ```bash
   # Run unit tests
   xcodebuild test -scheme breadcrumbs -destination 'platform=macOS'
   
   # Run UI tests
   xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsUITests
   ```

4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat: add new diagnostic tool for network analysis"
   ```

5. **Push and Create PR**:
   ```bash
   git push origin feature/new-diagnostic-tool
   # Create pull request on GitHub
   ```

### Commit Message Format

Use conventional commits:

```
type(scope): description

feat(tools): add network latency measurement tool
fix(ui): resolve chat message display issue
docs(readme): update installation instructions
test(vpn): add VPN detection edge case tests
refactor(api): simplify OpenAI model integration
```

### Code Review Process

1. **Self Review**: Review your own code before submitting
2. **Automated Checks**: Ensure CI passes
3. **Peer Review**: At least one reviewer required
4. **Testing**: Verify all tests pass
5. **Documentation**: Update docs if needed

## 🛠 Adding New Features

### Adding a New Diagnostic Tool

1. **Create Tool Implementation**:
   ```swift
   // Tools/NetworkLatencyTool.swift
   struct NetworkLatencyTool: AITool {
       let name = "network_latency"
       let description = "Measures network latency to specified hosts"
       
       var parametersSchema: ToolParameterSchema {
           ToolParameterSchema([
               "type": "object",
               "properties": [
                   "host": [
                       "type": "string",
                       "description": "Host to ping"
                   ]
               ],
               "required": ["host"]
           ])
       }
       
       func execute(arguments: [String: Any]) async throws -> String {
           guard let host = arguments["host"] as? String else {
               throw ToolError.invalidArguments("Host is required")
           }
           
           // Implementation
           let latency = try await measureLatency(to: host)
           return "Latency to \(host): \(latency)ms"
       }
   }
   ```

2. **Register in ToolRegistry**:
   ```swift
   // In AITool.swift
   private func registerDefaultTools() {
       register(VPNDetectorTool())
       register(DNSReachabilityTool())
       register(AppCheckerTool())
       register(SystemDiagnosticTool())
       register(NetworkLatencyTool()) // Add new tool
   }
   ```

3. **Add Tests**:
   ```swift
   // breadcrumbsTests/Tools/NetworkLatencyToolTests.swift
   final class NetworkLatencyToolTests: XCTestCase {
       
       func testNetworkLatencyTool() async throws {
           let tool = NetworkLatencyTool()
           let result = try await tool.execute(arguments: ["host": "google.com"])
           XCTAssertTrue(result.contains("Latency to google.com"))
       }
   }
   ```

4. **Update Documentation**:
   - Add tool description to FEATURES.md
   - Update API documentation
   - Add usage examples

### Adding a New AI Provider

1. **Create Provider Implementation**:
   ```swift
   // Models/AnthropicModel.swift
   final class AnthropicModel: AIModel {
       let providerId = "anthropic"
       let displayName = "Claude"
       let supportsTools = true
       
       private let apiKey: String
       
       init(apiKey: String) {
           self.apiKey = apiKey
       }
       
       func sendMessage(messages: [ChatMessage], tools: [AITool]?) async throws -> ChatMessage {
           // Implementation
       }
   }
   ```

2. **Add Configuration**:
   ```swift
   // In SettingsView.swift
   enum AIProvider: String, CaseIterable {
       case openai = "openai"
       case anthropic = "anthropic"
       
       var displayName: String {
           switch self {
           case .openai: return "OpenAI GPT"
           case .anthropic: return "Anthropic Claude"
           }
       }
   }
   ```

3. **Add Tests and Documentation**

## 🐛 Debugging

### Debug Configuration

1. **Enable Debug Logging**:
   ```swift
   // In Logger.swift
   static func debug(_ message: String, category: OSLog = general) {
       log(message, category: category, level: .debug)
   }
   ```

2. **Use Console.app**:
   - Open Console.app
   - Search for "breadcrumbs"
   - Filter by category (general, chat, tools, ui)

3. **Add Breakpoints**:
   - Set breakpoints in Xcode
   - Use LLDB commands for inspection

### Common Debug Scenarios

#### Tool Execution Issues

```swift
// Add logging to tool execution
func execute(arguments: [String: Any]) async throws -> String {
    Logger.tools("Tool \(name) executing with arguments: \(arguments)")
    
    do {
        let result = try await performOperation()
        Logger.tools("Tool \(name) completed successfully")
        return result
    } catch {
        Logger.tools("Tool \(name) failed: \(error)")
        throw error
    }
}
```

#### API Integration Issues

```swift
// Add request/response logging
func sendMessage(messages: [ChatMessage], tools: [AITool]?) async throws -> ChatMessage {
    Logger.tools("Sending \(messages.count) messages to OpenAI")
    
    let response = try await client.chats(query: query)
    Logger.tools("Received response: \(response)")
    
    return try convertResponse(response)
}
```

## 📊 Performance Optimization

### Memory Management

```swift
// Use weak references to prevent retain cycles
class ChatViewModel: ObservableObject {
    weak var delegate: ChatViewModelDelegate?
    
    deinit {
        // Clean up resources
        cancellables.removeAll()
    }
}
```

### Async Performance

```swift
// Use TaskGroup for concurrent operations
func collectSystemInfo() async throws -> SystemInfo {
    return try await withThrowingTaskGroup(of: SystemInfoComponent.self) { group in
        group.addTask { try await getCPUInfo() }
        group.addTask { try await getMemoryInfo() }
        group.addTask { try await getDiskInfo() }
        
        var components: [SystemInfoComponent] = []
        for try await component in group {
            components.append(component)
        }
        
        return SystemInfo(components: components)
    }
}
```

### UI Performance

```swift
// Use LazyVStack for large lists
LazyVStack {
    ForEach(messages) { message in
        MessageView(message: message)
    }
}

// Debounce user input
@State private var searchText = ""
@State private var searchTask: Task<Void, Never>?

func searchTextChanged(_ text: String) {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        await performSearch(text)
    }
}
```

## 🚀 Build and Deployment

### Build Configurations

1. **Debug**: Development with verbose logging
2. **Release**: Optimized production build
3. **Testing**: Unit test configuration

### Build Scripts

```bash
#!/bin/bash
# scripts/build.sh

set -e

echo "Building Breadcrumbs..."

# Clean build
xcodebuild clean -project breadcrumbs.xcodeproj -scheme breadcrumbs

# Build for release
xcodebuild build \
    -project breadcrumbs.xcodeproj \
    -scheme breadcrumbs \
    -configuration Release \
    -derivedDataPath ./build

echo "Build completed successfully!"
```

### Code Signing

For distribution:

1. **Create Developer ID Certificate**
2. **Configure Code Signing** in Xcode
3. **Notarize Application**:
   ```bash
   xcrun notarytool submit breadcrumbs.zip \
       --apple-id "your@email.com" \
       --password "app-specific-password" \
       --team-id "TEAM_ID"
   ```

## 📚 Documentation

### Code Documentation

Use Swift DocC for API documentation:

```swift
/// A tool that detects VPN connection status on macOS
///
/// This tool can identify various VPN types including:
/// - Personal VPN (IKEv2, IPSec)
/// - Tunnel Provider VPN
/// - Third-party VPN clients
///
/// ## Usage
///
/// ```swift
/// let vpnTool = VPNDetectorTool()
/// let result = try await vpnTool.execute(arguments: [:])
/// print(result) // "VPN Connection Status: Connected"
/// ```
///
/// - Parameter arguments: Tool arguments (currently none required)
/// - Returns: Formatted string describing VPN status
/// - Throws: `ToolError` if detection fails
struct VPNDetectorTool: AITool {
    // Implementation
}
```

### README Updates

When adding features:

1. **Update README.md** with new features
2. **Add usage examples**
3. **Update requirements** if needed
4. **Add screenshots** for UI changes

## 🤝 Contributing

### Contribution Guidelines

1. **Fork the repository**
2. **Create feature branch**
3. **Follow coding standards**
4. **Add tests**
5. **Update documentation**
6. **Submit pull request**

### Issue Templates

Use GitHub issue templates for:
- Bug reports
- Feature requests
- Documentation improvements

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

---

This development guide should help you contribute effectively to the Breadcrumbs project. For additional help, refer to the other documentation files or create an issue on GitHub.
