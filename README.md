# Breadcrumbs - AI-Powered System Diagnostics

[![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Building toward autonomous fleet management** - This POC demonstrates the foundational endpoint agent for a distributed AI-powered self-healing system, while providing immediate utility as a standalone diagnostic tool.

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

---

## 📑 Table of Contents

### 🚀 Getting Started
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Installation Guide](SETUP.md) - Detailed setup and configuration

### 📖 Core Documentation
- [Features Overview](FEATURES.md) - Complete feature list with POC-to-vision use cases
- [Architecture Guide](ARCHITECTURE.md) - System design and evolution roadmap
- [API Documentation](API.md) - REST API reference and agent protocol evolution

### 👨‍💻 Development
- [Development Guide](DEVELOPMENT.md) - Coding standards and workflows
- [Testing Documentation](TESTING.md) - Test strategy and guidelines
- [Contributing Guidelines](#-contributing)

### 📚 Additional Resources
- [Vision & Roadmap](#-vision-ai-powered-endpoint-self-healing)
- [Permissions Guide](PERMISSIONS.md)
- [License](#-license)

---

## 📋 Requirements

- **macOS**: 15.0 (Sequoia) or later
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later
- **OpenAI API Key**: Required for AI functionality

## ⚡ Quick Start

### Installation

**Option 1: Build from Source**
```bash
git clone https://github.com/yourusername/breadcrumbs.git
cd breadcrumbs
open breadcrumbs.xcodeproj
# Press Cmd+R in Xcode to build and run
```

**Option 2: Download Release**
1. Download from [Releases page](https://github.com/yourusername/breadcrumbs/releases)
2. Drag `Breadcrumbs.app` to Applications
3. Launch from Spotlight

📖 **Detailed instructions:** See [SETUP.md](SETUP.md)

### Configuration

1. **Get OpenAI API Key** from [platform.openai.com](https://platform.openai.com/api-keys)
2. **Launch Breadcrumbs** → Settings → API Key
3. **Paste key** and enable biometric protection
4. **Save** and start chatting

📖 **Detailed configuration:** See [SETUP.md](SETUP.md)

## 🎯 Usage Examples

| Query | AI Response |
|-------|-------------|
| "Is my VPN connected?" | Uses VPN detector → "Connected: IKEv2, utun0, 10.0.0.1" |
| "I can't reach google.com" | Uses DNS tool → "Reachable: YES, 45ms response time" |
| "What apps are running?" | Uses app checker → Lists all running applications |
| "Check system health" | Uses diagnostics → Reports crashes, memory, recommendations |

📖 **More examples and detailed features:** See [FEATURES.md](FEATURES.md)

## 🌐 Remote API Access

Start HTTP server: Settings → Server → Start Server (port 8181)

**Quick test:**
```bash
curl http://localhost:8181/api/v1/health
```

**Chat with diagnostics:**
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"message": "Check VPN status", "tools_enabled": true}'
```

📖 **Complete API reference:** See [API.md](API.md)

## 🔧 Diagnostic Tools

| Tool | Purpose | Key Capabilities |
|------|---------|------------------|
| **VPN Detector** | VPN monitoring | Status, type (IKEv2/IPSec/OpenVPN), IP, interface |
| **DNS Reachability** | Network testing | Domain resolution, latency, custom DNS servers |
| **App Checker** | Application info | Versions, running status, code signing, App Store |
| **System Diagnostic** | Health monitoring | Crash reports, performance metrics, recommendations |

📖 **Detailed tool documentation:** See [FEATURES.md](FEATURES.md) and [API.md](API.md)

## 🏗 Architecture

**Layered Design:**
```
UI Layer (SwiftUI)
    ↓
Business Logic (ViewModels, Services)
    ↓
AI Integration (OpenAI, Tool Registry)
    ↓
System Tools (VPN, DNS, Apps, Diagnostics)
```

**Key Design Principles:**
- **Protocol-based** - Easy to extend with new AI providers and tools
- **Async/await** - Non-blocking operations, streaming support
- **Vapor server** - RESTful API for remote access
- **Secure by default** - Keychain integration, biometric auth

📖 **Detailed architecture and POC evolution:** See [ARCHITECTURE.md](ARCHITECTURE.md)

## 🔒 Security & Privacy

- ✅ **Local processing** - All diagnostics run on your Mac
- ✅ **Biometric protection** - Touch ID/Face ID for API keys
- ✅ **No data collection** - Nothing sent except to OpenAI API
- ✅ **Keychain storage** - Secure credential management
- ✅ **HTTPS only** - Encrypted external communications

📖 **Detailed security info:** See [PERMISSIONS.md](PERMISSIONS.md)

## 👨‍💻 Development

**Quick start:**
```bash
git clone https://github.com/yourusername/breadcrumbs.git
cd breadcrumbs
open breadcrumbs.xcodeproj
```

**Run tests:**
```bash
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS'
```

**Project structure:**
```
breadcrumbs/
├── Models/      - Data models and AI integration
├── Protocols/   - AIModel, AITool interfaces
├── Tools/       - VPN, DNS, App, System diagnostics
├── ViewModels/  - Business logic
└── Views/       - SwiftUI interface
```

📖 **Complete development guide:** See [DEVELOPMENT.md](DEVELOPMENT.md)
📖 **Testing documentation:** See [TESTING.md](TESTING.md)

## 🤝 Contributing

Contributions welcome!

**Steps:**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and add tests
4. Submit pull request

📖 **Coding standards and workflow:** See [DEVELOPMENT.md](DEVELOPMENT.md)

---

## 📞 Support

- 🐛 [Report Issues](https://github.com/yourusername/breadcrumbs/issues)
- 💬 [Discussions](https://github.com/yourusername/breadcrumbs/discussions)
- 📖 Documentation: This README + linked guides

## 🙏 Acknowledgments

- **OpenAI** - GPT API powering AI diagnostics
- **Vapor** - Swift web framework for HTTP server
- **Apple** - macOS system APIs and Swift ecosystem

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🎯 Vision: AI-Powered Endpoint Self-Healing

### From POC to Autonomous Fleet Management

**The Problem:** Enterprise Mac fleets suffer from manual troubleshooting bottlenecks, limited visibility, and scaling challenges as distributed workforces grow.

**The Vision:** AI-powered autonomous endpoint agents that detect, diagnose, and remediate issues **before users notice** - coordinating across thousands of devices with minimal human intervention.

**This POC Validates:**

| Component | Proven in POC | Enables Future Capability |
|-----------|---------------|---------------------------|
| ✅ Protocol-based tools | `AITool` interface | Dynamic tool loading, plugin marketplace |
| ✅ REST API | Vapor HTTP server | Agent-to-agent communication |
| ✅ AI integration | OpenAI function calling | Local ML models, federated learning |
| ✅ Async execution | Swift concurrency | Background monitoring, streaming telemetry |
| ✅ Secure storage | Keychain + biometrics | Certificate-based agent authentication |

### Evolution Roadmap

| Phase | Timeline | Key Capabilities |
|-------|----------|------------------|
| **🔵 Phase 1: POC** (Current) | - | AI diagnostics, 4 tools, REST API, manual invocation |
| **🟢 Phase 2: Enhanced** | 3-6 months | Remediation actions, risk assessment, WebSocket streaming |
| **🟡 Phase 3: Control Tower** | 6-12 months | Fleet management, bidirectional comms, admin dashboard |
| **🟣 Phase 4: Autonomous** | 12-18+ months | Predictive diagnostics, federated learning, zero-touch resolution |

### Real-World Impact

**Example: VPN Connection Failure**

| Current POC | Future Vision |
|-------------|---------------|
| **Detection:** User asks "VPN broken?" | **Prediction:** Agent detects latency spike 60s before disconnect |
| **Diagnosis:** AI identifies disconnected VPN | **Prevention:** Preemptive reconnect to different server |
| **Action:** Provides troubleshooting steps | **Outcome:** Zero downtime, fleet-wide capacity alert |
| **Time:** Minutes of manual work | **Time:** Milliseconds, fully autonomous |

📖 **Complete vision, use cases, and technical evolution:** See [ARCHITECTURE.md](ARCHITECTURE.md) and [FEATURES.md](FEATURES.md)

## 🔮 Detailed Roadmap

### Near-term (Q1-Q2 2025)
- [ ] Add 6 remediation actions with rollback
- [ ] Structured telemetry output
- [ ] Risk assessment framework
- [ ] WebSocket streaming API

### Mid-term (Q3-Q4 2025)
- [ ] Control tower server MVP
- [ ] Admin dashboard
- [ ] Core ML anomaly detection
- [ ] Agent protocol specification

### Long-term (2026+)
- [ ] Federated learning
- [ ] Predictive diagnostics
- [ ] Multi-agent coordination
- [ ] Zero-touch resolution

📖 **Complete roadmap with technical details:** See [ARCHITECTURE.md](ARCHITECTURE.md)

---

<div align="center">

**Made with ❤️ for the macOS community**

*Immediate value as a standalone diagnostic tool. Built for evolution toward autonomous fleet management.*

</div>
