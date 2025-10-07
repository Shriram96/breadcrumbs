# Breadcrumbs - AI-Powered System Diagnostics

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Breadcrumbs is an intelligent macOS system diagnostic assistant that combines AI-powered analysis with comprehensive system monitoring tools. It provides real-time insights into VPN connectivity, network issues, application status, and system health through an intuitive chat interface.

## 🚀 Features

### Core Capabilities
- **AI-Powered Diagnostics**: Chat with an intelligent assistant that understands system issues
- **VPN Detection**: Comprehensive VPN connection monitoring and troubleshooting
- **Network Analysis**: DNS reachability testing and connectivity diagnostics
- **Application Monitoring**: Detailed app information, running status, and performance metrics
- **System Health**: Crash reports, performance metrics, and system diagnostics
- **Remote API Access**: HTTP server for external tool integration

### Security & Privacy
- **Biometric Authentication**: Touch ID/Face ID protection for API keys
- **Local Processing**: All diagnostics run locally on your machine
- **Secure Storage**: API keys stored in macOS Keychain with biometric protection
- **No Data Collection**: No user data is sent to external services

## 📋 Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later
- **OpenAI API Key**: Required for AI functionality

## 🛠 Installation

### Option 1: Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/breadcrumbs.git
   cd breadcrumbs
   ```

2. **Open in Xcode**:
   ```bash
   open breadcrumbs.xcodeproj
   ```

3. **Build and run**:
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

### Option 2: Download Release

1. Download the latest release from the [Releases page](https://github.com/yourusername/breadcrumbs/releases)
2. Open the downloaded `.dmg` file
3. Drag Breadcrumbs to your Applications folder
4. Launch from Applications or Spotlight

## ⚙️ Configuration

### Initial Setup

1. **Launch Breadcrumbs** from your Applications folder
2. **Configure API Key**:
   - Click the Settings button (gear icon)
   - Enter your OpenAI API key
   - Enable Touch ID/Face ID for enhanced security
   - Click "Save"

3. **Start Chatting**:
   - Ask questions like "Is my VPN connected?" or "Check my network connectivity"
   - The AI will use diagnostic tools to provide accurate answers

### API Key Setup

1. **Get an OpenAI API Key**:
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key (starts with `sk-`)

2. **Configure in Breadcrumbs**:
   - Open Settings → API Key tab
   - Paste your API key
   - Enable biometric protection (recommended)
   - Save to Keychain

## 🎯 Usage Examples

### VPN Diagnostics
```
User: "Is my VPN connected?"
AI: [Uses VPN detector tool] "Your VPN is currently connected. Connection details: IKEv2 VPN, Interface: utun0, IP: 10.0.0.1, Connected since: 2:30 PM"
```

### Network Troubleshooting
```
User: "I can't reach google.com"
AI: [Uses DNS reachability tool] "DNS resolution for google.com is working. Found A record: 142.250.191.14. Response time: 45ms. The issue might be with your internet connection or firewall settings."
```

### Application Information
```
User: "What version of Chrome do I have installed?"
AI: [Uses app checker tool] "Chrome version 120.0.6099.109 is installed and currently running. Bundle ID: com.google.Chrome, Last opened: Today at 1:15 PM"
```

### System Health Check
```
User: "Check my system for any issues"
AI: [Uses system diagnostic tool] "System health check completed. Found 2 crash reports in the last 24 hours from Safari. Memory usage is normal. No thermal issues detected. Recommendations: Update Safari to the latest version."
```

## 🌐 Remote API Access

Breadcrumbs includes an HTTP server for remote access to diagnostic capabilities:

### Start the Server
1. Open Settings → Server tab
2. Click "Start Server"
3. Note the API key and port (default: 8181)

### API Endpoints

#### Health Check
```bash
curl http://localhost:8181/api/v1/health
```

#### Chat with Diagnostics
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Check my VPN status",
    "tools_enabled": true
  }'
```

#### List Available Tools
```bash
curl http://localhost:8181/api/v1/tools \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## 🔧 Available Tools

### VPN Detector (`vpn_detector`)
- Detects VPN connection status
- Identifies VPN type (IKEv2, IPSec, OpenVPN, etc.)
- Shows connection details and IP addresses
- Supports Personal VPN and Tunnel Provider connections

### DNS Reachability (`dns_reachability`)
- Tests domain connectivity
- Performs DNS resolution (A, AAAA records)
- Measures response times
- Supports custom DNS servers

### App Checker (`app_checker`)
- Lists installed applications
- Shows app versions and bundle information
- Identifies running applications
- Provides code signing and App Store information

### System Diagnostic (`system_diagnostic`)
- Collects crash reports and system logs
- Monitors performance metrics
- Analyzes system health
- Provides troubleshooting recommendations

## 🏗 Architecture

Breadcrumbs follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│              Presentation Layer         │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   ChatView  │  │  SettingsView   │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Business Logic Layer         │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │ChatViewModel│  │  ServiceManager │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│             Data Access Layer           │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │  OpenAIModel│  │  ToolRegistry   │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│          System Integration Layer       │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Tools     │  │  KeychainHelper │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
```

## 🔒 Security Considerations

### Data Protection
- **Local Processing**: All diagnostic operations run locally
- **Secure Storage**: API keys stored in macOS Keychain
- **Biometric Protection**: Optional Touch ID/Face ID authentication
- **No Persistence**: Diagnostic results are not stored permanently

### Network Security
- **HTTPS Only**: All external API calls use encrypted connections
- **API Key Protection**: Keys are never logged or exposed in plain text
- **Local Server**: HTTP server runs on localhost only

### Permissions
The app requires the following permissions:
- **Network Access**: For OpenAI API calls and HTTP server
- **System Configuration**: For VPN and network diagnostics
- **File System Access**: For reading diagnostic reports
- **Biometric Authentication**: For secure keychain access

## 🧪 Testing

### Running Tests
```bash
# Unit tests
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS'

# UI tests
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsUITests
```

### Test Coverage
- **Unit Tests**: Core business logic and tool implementations
- **Integration Tests**: Component interactions and API integration
- **Mock Objects**: Protocol-based mocking for external dependencies
- **Test Helpers**: Utility functions for consistent testing

## 📚 Development

### Project Structure
```
breadcrumbs/
├── breadcrumbs/                 # Main application
│   ├── Models/                  # Data models
│   ├── Protocols/               # Protocol definitions
│   ├── Services/                # Business logic services
│   ├── Tools/                   # Diagnostic tools
│   ├── Utilities/               # Helper utilities
│   ├── ViewModels/              # SwiftUI view models
│   └── Views/                   # SwiftUI views
├── breadcrumbsTests/            # Unit tests
├── breadcrumbsUITests/          # UI tests
└── docs/                        # Documentation
```

### Adding New Tools

1. **Create Tool Implementation**:
   ```swift
   struct MyNewTool: AITool {
       let name = "my_new_tool"
       let description = "Description of what this tool does"
       
       var parametersSchema: ToolParameterSchema {
           // Define parameters
       }
       
       func execute(arguments: [String: Any]) async throws -> String {
           // Implement tool logic
       }
   }
   ```

2. **Register in ToolRegistry**:
   ```swift
   private func registerDefaultTools() {
       register(MyNewTool())
       // ... other tools
   }
   ```

3. **Add Tests**:
   ```swift
   func testMyNewTool() async throws {
       let tool = MyNewTool()
       let result = try await tool.execute(arguments: [:])
       XCTAssertFalse(result.isEmpty)
   }
   ```

### Code Style Guidelines

- **Swift Style**: Follow Apple's Swift API Design Guidelines
- **Documentation**: Document all public APIs with Swift DocC
- **Error Handling**: Use proper error types and localized descriptions
- **Async/Await**: Prefer modern Swift concurrency patterns
- **Testing**: Maintain high test coverage for critical paths

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `xcodebuild test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenAI**: For providing the GPT API that powers the AI assistant
- **Vapor**: For the excellent Swift web framework
- **Apple**: For the comprehensive macOS system APIs
- **Swift Community**: For the amazing ecosystem of packages

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/breadcrumbs/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/breadcrumbs/discussions)
- **Documentation**: [Wiki](https://github.com/yourusername/breadcrumbs/wiki)

## 🔮 Roadmap

### Upcoming Features
- [ ] **Multiple AI Providers**: Support for Anthropic, Google, and other AI services
- [ ] **Custom Tools**: User-defined diagnostic tools
- [ ] **Plugin System**: Dynamic tool loading and management
- [ ] **Cloud Integration**: Optional cloud storage for diagnostic history
- [ ] **Advanced Analytics**: Usage patterns and system health trends
- [ ] **Mobile Companion**: iOS app for remote monitoring

### Performance Improvements
- [ ] **Tool Caching**: Cache frequently used diagnostic results
- [ ] **Streaming UI**: Real-time tool execution updates
- [ ] **Background Monitoring**: Periodic system health checks
- [ ] **Optimized Queries**: Faster system information gathering

---

**Made with ❤️ for the macOS community**
