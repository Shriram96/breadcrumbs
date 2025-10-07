# 🚀 Features Documentation

This document provides a comprehensive overview of all features available in Breadcrumbs, including detailed descriptions, usage examples, and technical implementation details.

## 🎯 Core Features

### 1. AI-Powered Chat Interface

**Description**: Interactive chat interface powered by OpenAI's GPT models that can understand natural language queries about system diagnostics.

**User-Facing Functionality**:
- Natural language conversation about system issues
- Contextual understanding of diagnostic requests
- Intelligent tool selection based on user queries
- Clear, actionable responses with troubleshooting steps

**Technical Implementation**:
- **Files**: `ChatView.swift`, `ChatViewModel.swift`
- **Key Classes**: `ChatViewModel`, `OpenAIModel`
- **API Integration**: OpenAI Chat Completions API
- **Dependencies**: MacPaw/OpenAI Swift package

**Usage Examples**:
```
User: "Is my VPN connected?"
AI: "Let me check your VPN connection status..." [Uses VPN detector tool]

User: "I can't reach google.com"
AI: "I'll test the connectivity to google.com for you..." [Uses DNS reachability tool]

User: "What apps are currently running?"
AI: "Let me check your running applications..." [Uses app checker tool]
```

### 2. VPN Detection and Analysis

**Description**: Comprehensive VPN connection monitoring that detects various VPN types and provides detailed connection information.

**User-Facing Functionality**:
- Real-time VPN connection status
- VPN type identification (IKEv2, IPSec, OpenVPN, etc.)
- Connection details (IP address, interface, server info)
- Connection history and duration tracking

**Technical Implementation**:
- **Files**: `VPNDetectorTool.swift`
- **Key Classes**: `VPNDetectorTool`, `VPNDetectorOutput`
- **System APIs**: NetworkExtension, SystemConfiguration
- **Detection Methods**:
  - Personal VPN (NEVPNManager)
  - Tunnel Provider VPN (NETunnelProviderManager)
  - Interface-based detection (utun, ppp, tap interfaces)
  - SystemConfiguration VPN services

**Supported VPN Types**:
- **IKEv2/IPSec**: Native macOS VPN
- **OpenVPN**: Third-party VPN clients
- **PPTP/L2TP**: Legacy VPN protocols
- **Tunnel Provider**: Custom VPN implementations

**Usage Examples**:
```swift
// Tool execution
let vpnTool = VPNDetectorTool()
let result = try await vpnTool.execute(arguments: [:])
// Returns: "VPN Connection Status: Connected - IKEv2, Interface: utun0, IP: 10.0.0.1"
```

### 3. DNS Reachability Testing

**Description**: Network connectivity testing tool that performs DNS resolution and measures response times for domain names.

**User-Facing Functionality**:
- Domain connectivity testing
- DNS resolution verification
- Response time measurement
- Custom DNS server support
- IPv4 and IPv6 record support

**Technical Implementation**:
- **Files**: `DNSReachabilityTool.swift`
- **Key Classes**: `DNSReachabilityTool`, `DNSReachabilityOutput`
- **Dependencies**: Swift Async DNS Resolver
- **Record Types**: A, AAAA records
- **Features**: Custom DNS servers, timeout configuration

**Usage Examples**:
```swift
// Test specific domain
let dnsTool = DNSReachabilityTool()
let result = try await dnsTool.execute(arguments: [
    "domain": "google.com",
    "record_type": "A",
    "timeout": 5.0
])
// Returns: "DNS Reachability Check for google.com: YES - A: 142.250.191.14, Response Time: 0.045s"
```

### 4. Application Information and Monitoring

**Description**: Comprehensive application discovery and monitoring tool that provides detailed information about installed and running applications.

**User-Facing Functionality**:
- List all installed applications
- Show running application status
- Display app versions and bundle information
- Code signing and App Store information
- Application categorization and filtering

**Technical Implementation**:
- **Files**: `AppCheckerTool.swift`
- **Key Classes**: `AppCheckerTool`, `AppInfo`, `CodeSigningInfo`
- **System APIs**: NSWorkspace, Bundle, FileManager
- **Information Sources**:
  - Bundle metadata
  - File system attributes
  - Code signing certificates
  - App Store receipts
  - Launch services

**Supported Information**:
- **Basic Info**: Name, version, bundle ID, path
- **Status**: Running state, launch date, last opened
- **Security**: Code signing, App Store status
- **System**: Architecture, minimum OS version
- **Metadata**: Developer, category, file types

**Usage Examples**:
```swift
// Find specific app
let appTool = AppCheckerTool()
let result = try await appTool.execute(arguments: [
    "app_name": "Chrome",
    "running_apps_only": true
])
// Returns: "Chrome version 120.0.6099.109 is running, Bundle ID: com.google.Chrome"
```

### 5. System Diagnostic Reports

**Description**: Comprehensive system health monitoring that collects crash reports, performance metrics, and system diagnostics.

**User-Facing Functionality**:
- Crash report analysis
- System performance metrics
- Memory and CPU usage monitoring
- Thermal and battery status
- System health recommendations

**Technical Implementation**:
- **Files**: `SystemDiagnosticTool.swift`
- **Key Classes**: `SystemDiagnosticTool`, `SystemDiagnosticReport`
- **System APIs**: FileManager, ProcessInfo, SystemConfiguration
- **Data Sources**:
  - Diagnostic reports directory
  - System logs
  - Process information
  - Hardware statistics

**Diagnostic Types**:
- **Crash Reports**: Application crash analysis
- **Spin Reports**: Unresponsive application detection
- **Jetsam Reports**: Memory pressure events
- **Thermal Reports**: System temperature monitoring
- **Performance Metrics**: CPU, memory, disk usage

**Usage Examples**:
```swift
// Full system diagnostic
let sysTool = SystemDiagnosticTool()
let result = try await sysTool.execute(arguments: [
    "diagnostic_type": "all",
    "time_range_hours": 24
])
// Returns comprehensive system health report with recommendations
```

## 🌐 Remote Access Features

### 6. HTTP API Server

**Description**: Built-in HTTP server that provides RESTful API access to all diagnostic capabilities for external tool integration.

**User-Facing Functionality**:
- RESTful API endpoints
- Bearer token authentication
- Real-time diagnostic access
- Tool execution via HTTP
- Health monitoring endpoints

**Technical Implementation**:
- **Files**: `VaporServer.swift`, `ServiceManager.swift`
- **Key Classes**: `VaporServer`, `ServiceManager`
- **Dependencies**: Vapor web framework
- **Endpoints**:
  - `GET /api/v1/health` - Server health check
  - `GET /api/v1/tools` - Available tools list
  - `POST /api/v1/chat` - Chat completion with tools

**API Features**:
- **Authentication**: Bearer token with configurable API keys
- **CORS Support**: Cross-origin request handling
- **Error Handling**: Comprehensive error responses
- **Timeout Protection**: Request timeout management
- **Logging**: Detailed request/response logging

**Usage Examples**:
```bash
# Health check
curl http://localhost:8181/api/v1/health

# Chat with diagnostics
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"message": "Check my VPN status", "tools_enabled": true}'
```

### 7. Server Management Interface

**Description**: User interface for configuring and managing the HTTP server, including port settings, API key management, and server status monitoring.

**User-Facing Functionality**:
- Server start/stop controls
- Port configuration
- API key generation and management
- Server status monitoring
- API usage examples

**Technical Implementation**:
- **Files**: `ServerSettingsView.swift`
- **Key Classes**: `ServerSettingsView`, `ServiceManager`
- **Features**:
  - Real-time status updates
  - Configuration validation
  - API key generation
  - Port conflict detection

## 🔐 Security Features

### 8. Biometric Authentication

**Description**: Touch ID/Face ID integration for secure access to stored API keys and sensitive data.

**User-Facing Functionality**:
- Biometric authentication prompts
- Secure keychain access
- Optional biometric protection
- Fallback to password authentication

**Technical Implementation**:
- **Files**: `KeychainHelper.swift`, `KeychainProtocol.swift`
- **Key Classes**: `KeychainHelper`
- **System APIs**: LocalAuthentication, Security
- **Features**:
  - Biometric availability detection
  - Secure keychain storage
  - Authentication context management
  - Error handling and fallbacks

**Security Features**:
- **Access Control**: Biometric-protected keychain items
- **Secure Storage**: Keychain with device-only access
- **Authentication Reuse**: Configurable authentication duration
- **Fallback Support**: Password fallback when biometrics unavailable

### 9. Secure Keychain Integration

**Description**: Secure storage and retrieval of sensitive data using macOS Keychain with optional biometric protection.

**User-Facing Functionality**:
- Secure API key storage
- Biometric-protected access
- Automatic keychain management
- Cross-app key sharing

**Technical Implementation**:
- **Files**: `KeychainHelper.swift`
- **Key Classes**: `KeychainHelper`
- **System APIs**: Security framework
- **Features**:
  - Generic password storage
  - Access control lists
  - Biometric integration
  - Error handling

## 🎨 User Interface Features

### 10. Modern SwiftUI Interface

**Description**: Native macOS interface built with SwiftUI providing an intuitive and responsive user experience.

**User-Facing Functionality**:
- Clean, modern interface design
- Responsive layout and animations
- Dark mode support
- Accessibility features
- Keyboard shortcuts

**Technical Implementation**:
- **Files**: `ContentView.swift`, `ChatView.swift`, `SettingsView.swift`
- **Key Classes**: Various SwiftUI Views
- **Features**:
  - Adaptive layouts
  - Animation support
  - Accessibility labels
  - Keyboard navigation

### 11. Message Grouping and Display

**Description**: Intelligent message grouping that organizes chat messages and tool usage for better readability.

**User-Facing Functionality**:
- Tool usage visualization
- Collapsible tool details
- Message threading
- Clear conversation flow

**Technical Implementation**:
- **Files**: `ChatView.swift`
- **Key Classes**: `MessageGroupView`, `ToolUsageGroup`
- **Features**:
  - Dynamic message grouping
  - Tool call visualization
  - Expandable details
  - Smooth animations

## 🔧 Advanced Features

### 12. Tool Registry System

**Description**: Dynamic tool registration and management system that allows for easy addition of new diagnostic capabilities.

**User-Facing Functionality**:
- Automatic tool discovery
- Tool availability status
- Dynamic tool loading
- Tool execution monitoring

**Technical Implementation**:
- **Files**: `AITool.swift` (ToolRegistry)
- **Key Classes**: `ToolRegistry`
- **Features**:
  - Protocol-based tool interface
  - Dynamic registration
  - Tool validation
  - Execution monitoring

### 13. Comprehensive Logging System

**Description**: Structured logging system that provides detailed debugging information across all application components.

**User-Facing Functionality**:
- Debug information access
- Performance monitoring
- Error tracking
- System diagnostics

**Technical Implementation**:
- **Files**: `Logger.swift`
- **Key Classes**: `Logger`
- **System APIs**: OSLog
- **Features**:
  - Categorized logging
  - Log levels
  - Performance optimization
  - Debug information

## 📊 Performance Features

### 14. Async/Await Integration

**Description**: Modern Swift concurrency patterns for responsive user interface and efficient background processing.

**User-Facing Functionality**:
- Non-blocking UI operations
- Responsive user interface
- Background processing
- Efficient resource usage

**Technical Implementation**:
- **Swift Concurrency**: async/await patterns
- **Task Management**: Proper task cancellation
- **Main Actor**: UI updates on main thread
- **Background Processing**: Tool execution off main thread

### 15. Memory Management

**Description**: Efficient memory usage patterns with proper cleanup and resource management.

**User-Facing Functionality**:
- Low memory footprint
- Responsive performance
- Efficient resource usage
- Automatic cleanup

**Technical Implementation**:
- **Weak References**: Prevent retain cycles
- **Automatic Cleanup**: Proper deinitialization
- **Resource Pooling**: Efficient resource reuse
- **Memory Monitoring**: Usage tracking

## 🔮 Future Features

### Planned Enhancements

1. **Multiple AI Providers**
   - Anthropic Claude integration
   - Google Gemini support
   - Local model support

2. **Custom Tool Development**
   - User-defined tools
   - Tool marketplace
   - Plugin system

3. **Advanced Analytics**
   - Usage patterns
   - System health trends
   - Performance metrics

4. **Cloud Integration**
   - Optional cloud storage
   - Cross-device synchronization
   - Remote monitoring

5. **Mobile Companion**
   - iOS app for remote monitoring
   - Push notifications
   - Mobile-specific tools

## 🧪 Testing Features

### 16. Comprehensive Test Suite

**Description**: Extensive testing framework covering unit tests, integration tests, and UI tests.

**Technical Implementation**:
- **Unit Tests**: Individual component testing
- **Integration Tests**: Component interaction testing
- **UI Tests**: End-to-end user workflow testing
- **Mock Objects**: Protocol-based mocking

**Test Coverage**:
- **Core Logic**: ViewModels and business logic
- **Tool Implementation**: All diagnostic tools
- **API Integration**: OpenAI and server APIs
- **User Interface**: SwiftUI view testing

## 📈 Monitoring and Analytics

### 17. Performance Monitoring

**Description**: Built-in performance monitoring and analytics for system health and usage patterns.

**Features**:
- Response time tracking
- Memory usage monitoring
- CPU usage analysis
- Error rate tracking

### 18. Usage Analytics

**Description**: Anonymous usage analytics to understand feature adoption and system health patterns.

**Features**:
- Feature usage tracking
- Performance metrics
- Error reporting
- System health trends

---

This comprehensive feature set makes Breadcrumbs a powerful and versatile system diagnostic tool that combines the intelligence of AI with the depth of native macOS system integration.
