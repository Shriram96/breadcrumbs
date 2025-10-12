# 🌐 API Documentation

This document provides comprehensive documentation for the Breadcrumbs HTTP API, including endpoints, authentication, data models, and usage examples.

## 📡 API Overview

The Breadcrumbs HTTP API provides programmatic access to all diagnostic capabilities through RESTful endpoints. The API is built using the Vapor web framework and runs locally on your machine.

### Base URL

```
http://localhost:8181/api/v1
```

### Authentication

All API endpoints (except health check) require Bearer token authentication:

```http
Authorization: Bearer YOUR_API_KEY
```

### Content Type

All requests and responses use JSON:

```http
Content-Type: application/json
```

## 🔐 Authentication

### API Key Management

API keys are generated and managed through the Breadcrumbs application:

1. **Open Settings** → Server tab
2. **Generate API Key** or use existing key
3. **Copy the key** for use in API requests

### Authentication Header

Include the API key in the Authorization header:

```http
Authorization: Bearer abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

### Key Security

- **Local Only**: API keys are stored locally in the application
- **No Network Transmission**: Keys are never sent over the network except in API requests
- **Configurable**: Keys can be regenerated at any time
- **Bearer Token**: Standard Bearer token authentication

## 📋 Endpoints

### Health Check

Check if the API server is running and healthy.

```http
GET /api/v1/health
```

**Authentication**: None required

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "uptime": "5 requests processed",
  "tools_available": 4
}
```

**Response Fields**:
- `status`: Server health status ("healthy" or "unhealthy")
- `timestamp`: Current server timestamp
- `uptime`: Server uptime information
- `tools_available`: Number of available diagnostic tools

**Example**:
```bash
curl http://localhost:8181/api/v1/health
```

### List Available Tools

Get a list of all available diagnostic tools.

```http
GET /api/v1/tools
```

**Authentication**: Required

**Response**:
```json
{
  "tools": [
    {
      "name": "vpn_detector",
      "description": "Detects if the system is currently connected to a VPN",
      "parameters": {}
    },
    {
      "name": "dns_reachability",
      "description": "Checks if a domain is reachable via DNS resolution",
      "parameters": {}
    },
    {
      "name": "app_checker",
      "description": "Comprehensive tool for checking installed applications",
      "parameters": {}
    },
    {
      "name": "system_diagnostic",
      "description": "Collects comprehensive system diagnostic reports",
      "parameters": {}
    }
  ]
}
```

**Response Fields**:
- `tools`: Array of available tools
  - `name`: Tool identifier
  - `description`: Human-readable description
  - `parameters`: Tool parameter schema (simplified)

**Example**:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     http://localhost:8181/api/v1/tools
```

### Chat Completion

Send a message to the AI assistant with optional tool usage.

```http
POST /api/v1/chat
```

**Authentication**: Required

**Request Body**:
```json
{
  "message": "Check my VPN status",
  "conversation_id": "optional-conversation-id",
  "tools_enabled": true
}
```

**Request Fields**:
- `message` (required): The user's message/question
- `conversation_id` (optional): Conversation identifier for context
- `tools_enabled` (optional): Whether to enable tool usage (default: true)

**Response**:
```json
{
  "response": "Your VPN is currently connected. Connection details: IKEv2 VPN, Interface: utun0, IP: 10.0.0.1, Connected since: 2:30 PM",
  "conversation_id": "conv_123456789",
  "timestamp": "2024-01-15T10:30:00Z",
  "tools_used": ["vpn_detector"]
}
```

**Response Fields**:
- `response`: The AI's response message
- `conversation_id`: Unique conversation identifier
- `timestamp`: Response timestamp
- `tools_used`: Array of tools that were executed

**Example**:
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Check my VPN status",
    "tools_enabled": true
  }'
```

## 🛠 Tool-Specific Usage

### VPN Detector Tool

Detect VPN connection status and details.

**Tool Name**: `vpn_detector`

**Parameters**:
```json
{
  "interface_name": "utun0"  // Optional: specific interface to check
}
```

**Example Request**:
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Check my VPN connection status",
    "tools_enabled": true
  }'
```

**Example Response**:
```json
{
  "response": "VPN Connection Status:\n- Connected: YES\n- VPN Type: IKEv2\n- Interface: utun0\n- IP Address: 10.0.0.1\n- Connected Since: 2:30 PM",
  "conversation_id": "conv_123456789",
  "timestamp": "2024-01-15T10:30:00Z",
  "tools_used": ["vpn_detector"]
}
```

### DNS Reachability Tool

Test domain connectivity and DNS resolution.

**Tool Name**: `dns_reachability`

**Parameters**:
```json
{
  "domain": "google.com",           // Required: domain to test
  "record_type": "A",               // Optional: DNS record type (A, AAAA)
  "dns_server": "8.8.8.8",         // Optional: custom DNS server
  "timeout": 5.0                    // Optional: timeout in seconds
}
```

**Example Request**:
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Test connectivity to google.com",
    "tools_enabled": true
  }'
```

**Example Response**:
```json
{
  "response": "DNS Reachability Check for google.com:\n- Reachable: YES\n- Response Time: 0.045s\n- DNS Records Found (1):\n  • A: 142.250.191.14 (TTL: 300s)",
  "conversation_id": "conv_123456789",
  "timestamp": "2024-01-15T10:30:00Z",
  "tools_used": ["dns_reachability"]
}
```

### App Checker Tool

Get information about installed applications.

**Tool Name**: `app_checker`

**Parameters**:
```json
{
  "app_name": "Chrome",                    // Optional: specific app name
  "bundle_identifier": "com.google.Chrome", // Optional: bundle ID
  "category": "web_browsers",              // Optional: app category
  "include_system_apps": false,            // Optional: include system apps
  "running_apps_only": true,               // Optional: only running apps
  "max_results": 100                       // Optional: max results (1-500)
}
```

**Example Request**:
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "What version of Chrome is installed?",
    "tools_enabled": true
  }'
```

**Example Response**:
```json
{
  "response": "Chrome version 120.0.6099.109 is installed and currently running. Bundle ID: com.google.Chrome, Last opened: Today at 1:15 PM, Code Signed: Yes",
  "conversation_id": "conv_123456789",
  "timestamp": "2024-01-15T10:30:00Z",
  "tools_used": ["app_checker"]
}
```

### System Diagnostic Tool

Collect comprehensive system diagnostic information.

**Tool Name**: `system_diagnostic`

**Parameters**:
```json
{
  "app_name": "Safari",                    // Optional: focus on specific app
  "bundle_identifier": "com.apple.Safari", // Optional: focus on specific bundle
  "diagnostic_type": "all",                // Optional: type of diagnostics
  "time_range_hours": 24,                  // Optional: time range in hours
  "include_system_reports": true,          // Optional: include system reports
  "include_user_reports": true,            // Optional: include user reports
  "collect_app_samples": true,             // Optional: collect app samples
  "max_reports_per_type": 50               // Optional: max reports per type
}
```

**Example Request**:
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Check my system for any issues",
    "tools_enabled": true
  }'
```

**Example Response**:
```json
{
  "response": "System health check completed. Found 2 crash reports in the last 24 hours from Safari. Memory usage is normal. No thermal issues detected. Recommendations: Update Safari to the latest version.",
  "conversation_id": "conv_123456789",
  "timestamp": "2024-01-15T10:30:00Z",
  "tools_used": ["system_diagnostic"]
}
```

## 📊 Data Models

### ChatMessage

Represents a message in the conversation.

```swift
struct ChatMessage: Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let toolCalls: [ToolCall]?
    let toolCallId: String?
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case tool
}
```

### ToolCall

Represents a tool execution request.

```swift
struct ToolCall: Codable {
    let id: String
    let name: String
    let arguments: String  // JSON string
}
```

### HealthResponse

Health check response structure.

```swift
struct HealthResponse: Codable {
    let status: String
    let timestamp: Date
    let uptime: String
    let toolsAvailable: Int
}
```

### ChatRequest

Chat completion request structure.

```swift
struct ChatRequest: Codable {
    let message: String
    let conversationId: String?
    let toolsEnabled: Bool
}
```

### ChatResponse

Chat completion response structure.

```swift
struct ChatResponse: Codable {
    let response: String
    let conversationId: String
    let timestamp: Date
    let toolsUsed: [String]
}
```

## 🔧 Error Handling

### Error Response Format

All errors follow a consistent format:

```json
{
  "error": "Error description",
  "code": "ERROR_CODE",
  "details": "Additional error details"
}
```

### Common Error Codes

- `UNAUTHORIZED`: Missing or invalid API key
- `INVALID_REQUEST`: Malformed request body
- `TOOL_EXECUTION_FAILED`: Tool execution error
- `AI_MODEL_ERROR`: AI model communication error
- `INTERNAL_SERVER_ERROR`: Unexpected server error

### HTTP Status Codes

- `200 OK`: Successful request
- `400 Bad Request`: Invalid request format
- `401 Unauthorized`: Missing or invalid authentication
- `500 Internal Server Error`: Server error

### Example Error Response

```json
{
  "error": "Invalid API key",
  "code": "UNAUTHORIZED",
  "details": "The provided API key is invalid or expired"
}
```

## 🌐 CORS Configuration

The API includes CORS middleware for cross-origin requests:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

## 📝 Usage Examples

### Python Client

```python
import requests
import json

class BreadcrumbsClient:
    def __init__(self, base_url="http://localhost:8181", api_key=None):
        self.base_url = base_url
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
    
    def health_check(self):
        """Check API health"""
        response = requests.get(f"{self.base_url}/api/v1/health")
        return response.json()
    
    def list_tools(self):
        """List available tools"""
        response = requests.get(
            f"{self.base_url}/api/v1/tools",
            headers=self.headers
        )
        return response.json()
    
    def chat(self, message, tools_enabled=True):
        """Send chat message"""
        data = {
            "message": message,
            "tools_enabled": tools_enabled
        }
        response = requests.post(
            f"{self.base_url}/api/v1/chat",
            headers=self.headers,
            json=data
        )
        return response.json()

# Usage
client = BreadcrumbsClient(api_key="your-api-key")

# Health check
health = client.health_check()
print(f"Status: {health['status']}")

# Chat with diagnostics
response = client.chat("Check my VPN status")
print(f"Response: {response['response']}")
```

### JavaScript Client

```javascript
class BreadcrumbsClient {
    constructor(baseUrl = 'http://localhost:8181', apiKey) {
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
        };
    }
    
    async healthCheck() {
        const response = await fetch(`${this.baseUrl}/api/v1/health`);
        return await response.json();
    }
    
    async listTools() {
        const response = await fetch(`${this.baseUrl}/api/v1/tools`, {
            headers: this.headers
        });
        return await response.json();
    }
    
    async chat(message, toolsEnabled = true) {
        const response = await fetch(`${this.baseUrl}/api/v1/chat`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify({
                message,
                tools_enabled: toolsEnabled
            })
        });
        return await response.json();
    }
}

// Usage
const client = new BreadcrumbsClient('http://localhost:8181', 'your-api-key');

// Health check
const health = await client.healthCheck();
console.log(`Status: ${health.status}`);

// Chat with diagnostics
const response = await client.chat('Check my VPN status');
console.log(`Response: ${response.response}`);
```

### cURL Examples

#### Basic Health Check
```bash
curl http://localhost:8181/api/v1/health
```

#### List Available Tools
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     http://localhost:8181/api/v1/tools
```

#### VPN Status Check
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Is my VPN connected?",
    "tools_enabled": true
  }'
```

#### Network Connectivity Test
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Test connectivity to google.com",
    "tools_enabled": true
  }'
```

#### Application Information
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "What apps are currently running?",
    "tools_enabled": true
  }'
```

#### System Health Check
```bash
curl -X POST http://localhost:8181/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "message": "Check my system for any issues",
    "tools_enabled": true
  }'
```

## 🔒 Security Considerations

### API Key Security

- **Cryptographically Secure Generation**: API keys are generated using `SecRandomCopyBytes` for cryptographic security
- **Local Storage**: API keys are stored locally in the application
- **Bearer Token**: Standard Bearer token authentication with constant-time comparison to prevent timing attacks
- **No Persistence**: Keys are not stored on the server
- **Regeneration**: Keys can be regenerated at any time

### Network Security

- **Localhost Only**: Server runs on localhost by default (127.0.0.1)
- **HTTPS**: All external API calls use HTTPS
- **No Data Collection**: No user data is collected or transmitted
- **Request Size Limits**: 10MB maximum request body size to prevent DoS attacks

### Input Validation

- **Message Length Limits**: Maximum 100,000 characters per message
- **Empty Message Detection**: Rejects empty messages
- **Pattern Detection**: Monitors for suspicious patterns (XSS, injection attempts) with security logging
- **Client Identification**: Logs client IP for all validation failures

### Security Logging

All security-relevant events are logged to the `security` category:
- Authentication failures (with client IP)
- Input validation failures
- Suspicious pattern detection
- Server start/stop events
- API key generation/updates

**View security logs**:
```bash
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security"' --last 1h
```

See [SECURITY.md](SECURITY.md) for complete security documentation.

### Rate Limiting

Currently, no rate limiting is implemented. See [SECURITY.md](SECURITY.md) for recommendations:

```swift
// Example rate limiting middleware
struct RateLimitMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // Implement rate limiting logic
        return next.respond(to: request)
    }
}
```

## 🚀 Performance Optimization

### Response Times

Typical response times:
- **Health Check**: < 10ms
- **Tool List**: < 50ms
- **Chat with Tools**: 1-5 seconds (depending on tool complexity)

### Caching

Consider implementing caching for frequently requested data:

```swift
// Example caching middleware
struct CacheMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // Implement caching logic
        return next.respond(to: request)
    }
}
```

### Timeout Configuration

Default timeouts:
- **Request Timeout**: 30 seconds
- **Tool Execution**: 10 seconds per tool
- **AI Model**: 30 seconds

## 📊 Monitoring and Logging

### Request Logging

All API requests are logged with:
- Timestamp
- Request method and path
- Response status
- Processing time
- Tools used (for chat requests)

### Error Logging

Errors are logged with:
- Error type and message
- Stack trace
- Request context
- User agent and IP

### Performance Metrics

Monitor:
- Request count and response times
- Tool execution times
- AI model response times
- Memory and CPU usage

## 🔄 API Evolution: REST → Agent Protocol

### Current POC API (Phase 1)

The current HTTP REST API demonstrates **endpoint-to-server** communication patterns that form the foundation for future agent-to-agent protocols.

**POC Capabilities:**
- ✅ RESTful endpoints for diagnostics
- ✅ Bearer token authentication
- ✅ JSON request/response
- ✅ Tool execution via HTTP

**Architectural Foundation:**
- Request/response pattern proves viability
- JSON-based messaging supports rich context
- Bearer auth extends to mutual TLS
- Stateless design enables scaling

### Phase 2: Enhanced Communication (6-12 months)

**WebSocket Streaming API**

```javascript
// Endpoint streaming connection
const ws = new WebSocket('ws://localhost:8181/api/v1/stream');

// Authenticate
ws.send(JSON.stringify({
    type: 'auth',
    token: 'YOUR_API_KEY'
}));

// Stream telemetry events
ws.send(JSON.stringify({
    type: 'telemetry',
    data: {
        vpn_status: { connected: true, latency: 45 },
        system_health: { memory: 8.2, cpu: 23.5 },
        timestamp: Date.now()
    }
}));

// Receive remediation commands
ws.onmessage = (event) => {
    const message = JSON.parse(event.data);
    if (message.type === 'remediation_request') {
        // Execute action and report result
        executeAction(message.action);
    }
};
```

**Bidirectional Capabilities:**
- Real-time telemetry streaming
- Server-initiated commands
- State synchronization
- Event notifications

### Phase 3: Agent Protocol (12-18 months)

**Semantic Message Types**

```swift
// Agent Protocol Messages
enum AgentMessage: Codable {
    case telemetry(TelemetryEvent)
    case remediationRequest(RemediationAction)
    case stateSync(SystemState)
    case escalation(EscalationRequest)
    case peerQuery(PeerQuery)
    case knowledgeShare(KnowledgeUpdate)
}

// Telemetry Event
struct TelemetryEvent: Codable {
    let endpoint_id: UUID
    let timestamp: Date
    let metrics: [String: Double]
    let anomalies: [Anomaly]?
    let predictions: [Prediction]?
}

// Remediation Action
struct RemediationAction: Codable {
    let action_id: UUID
    let action_type: String
    let parameters: [String: Any]
    let risk_level: RiskLevel
    let requires_approval: Bool
    let rollback_available: Bool
}

// State Synchronization
struct SystemState: Codable {
    let endpoint_id: UUID
    let last_sync: Date
    let health_status: HealthStatus
    let active_issues: [Issue]
    let recent_actions: [ActionHistory]
}

// Escalation Request
struct EscalationRequest: Codable {
    let issue_id: UUID
    let severity: Severity
    let context: DiagnosticContext
    let attempted_resolutions: [ActionHistory]
    let requires_human: Bool
}
```

**Agent-to-Agent Communication**

```swift
class AgentProtocol {
    // Connect to control tower
    func connectToControlTower(url: URL) async throws {
        // Establish secure WebSocket with mutual TLS
        // Authenticate with certificate
        // Begin state synchronization
    }

    // Send telemetry
    func sendTelemetry(_ event: TelemetryEvent) async throws {
        let message = AgentMessage.telemetry(event)
        try await send(message)
    }

    // Request peer assistance
    func queryPeers(_ query: PeerQuery) async throws -> [PeerResponse] {
        let message = AgentMessage.peerQuery(query)
        try await send(message)
        return try await receivePeerResponses()
    }

    // Escalate to control tower
    func escalate(_ request: EscalationRequest) async throws -> EscalationResponse {
        let message = AgentMessage.escalation(request)
        try await send(message)
        return try await receiveEscalationResponse()
    }

    // Handle incoming messages
    func handleIncoming(_ message: AgentMessage) async throws {
        switch message {
        case .remediationRequest(let action):
            try await executeRemediation(action)
        case .stateSync(let state):
            try await synchronizeState(state)
        case .peerQuery(let query):
            let response = try await resolvePeerQuery(query)
            try await sendPeerResponse(response)
        case .knowledgeShare(let update):
            try await updateLocalKnowledge(update)
        default:
            break
        }
    }
}
```

### Phase 4: Distributed Intelligence (18+ months)

**Collaborative Problem Solving**

```swift
// Multi-agent coordination
class CollaborativeAgent {
    let localIntelligence: LocalMLModel
    let controlTowerAgent: ControlTowerClient
    let peerNetwork: PeerNetwork

    func diagnoseAndResolve(_ problem: Problem) async throws -> Solution {
        // Step 1: Local analysis
        let localAnalysis = try await localIntelligence.analyze(problem)

        if localAnalysis.confidence > 0.9 {
            // High confidence - resolve locally
            return try await executeLocalSolution(localAnalysis.solution)
        }

        // Step 2: Query peers for similar issues
        let peerQuery = PeerQuery(
            problem_signature: problem.signature,
            context: problem.context
        )
        let peerResponses = try await peerNetwork.query(peerQuery)

        if let consensus = findConsensus(peerResponses), consensus.confidence > 0.85 {
            // Peer consensus - execute shared solution
            localIntelligence.learn(problem, solution: consensus.solution)
            return try await executeSolution(consensus.solution)
        }

        // Step 3: Escalate to control tower
        let escalation = EscalationRequest(
            issue: problem,
            local_analysis: localAnalysis,
            peer_responses: peerResponses,
            requires_human: localAnalysis.risk_level == .high
        )

        let towerResponse = try await controlTowerAgent.escalate(escalation)

        if towerResponse.requires_human_approval {
            // High-risk - require admin approval
            return try await requestHumanApproval(towerResponse)
        } else {
            // Control tower has high-confidence solution
            return try await executeSolution(towerResponse.solution)
        }
    }
}
```

**Federated Learning API**

```swift
// Control Tower → Endpoints: Model update
POST /api/v2/agent/model_update
{
    "model_id": "anomaly_detector_v2.3",
    "model_type": "core_ml",
    "encrypted_model": "base64_encoded_model",
    "signature": "model_signature",
    "metadata": {
        "trained_on_endpoints": 1250,
        "accuracy": 0.94,
        "false_positive_rate": 0.02,
        "deployment_group": "beta"
    }
}

// Endpoint → Control Tower: Local gradient update
POST /api/v2/agent/gradient_update
{
    "endpoint_id": "uuid",
    "model_id": "anomaly_detector_v2.3",
    "encrypted_gradients": "base64_encoded_gradients",
    "training_samples": 150,
    "privacy_budget_used": 0.1
}

// Control Tower → Admin: Fleet insights
GET /api/v2/admin/fleet_insights
{
    "total_endpoints": 5000,
    "active_issues": 23,
    "auto_resolved_today": 147,
    "escalations_today": 5,
    "top_issues": [
        {
            "type": "vpn_disconnection",
            "frequency": 45,
            "auto_resolution_rate": 0.98,
            "avg_resolution_time_ms": 3200
        }
    ],
    "fleet_health_score": 0.96,
    "recommendations": [
        "VPN server A at 92% capacity - recommend scaling",
        "Slack 4.35.126 cache corruption affecting 8% of fleet - recommend update push"
    ]
}
```

### API Evolution Comparison

| Capability | POC API | Phase 2 API | Vision API |
|------------|---------|-------------|------------|
| **Communication** | HTTP REST | REST + WebSocket | Agent Protocol |
| **Direction** | Unidirectional | Bidirectional | Multi-directional |
| **State** | Stateless | Session-based | Synchronized |
| **Auth** | Bearer token | Mutual TLS | Certificate + Zero-trust |
| **Messages** | Request/response | Events + commands | Semantic agent messages |
| **Coordination** | None | Tower-endpoint | Multi-agent mesh |
| **Learning** | None | Action history | Federated ML |
| **Latency** | 100-500ms | 10-50ms (WS) | < 10ms (persistent) |

### Technical Migration Path

**POC → Phase 2: Add WebSocket**
```swift
// Extend existing VaporServer (minimal changes)
func configureRoutes(_ app: Application) throws {
    // Existing REST routes
    app.get("api", "v1", "health", use: healthCheck)
    app.post("api", "v1", "chat", use: chat)

    // NEW: WebSocket streaming
    app.webSocket("api", "v1", "stream") { req, ws in
        // Authenticate via query parameter or first message
        let authenticated = try await authenticateWebSocket(ws)
        guard authenticated else {
            try await ws.close(code: .protocolCode(1008))
            return
        }

        // Bidirectional message handling
        for try await message in ws {
            let agentMessage = try JSONDecoder().decode(AgentMessage.self, from: message)
            let response = try await handleAgentMessage(agentMessage)
            try await ws.send(response.json)
        }
    }
}
```

**Phase 2 → Phase 3: Semantic Protocol**
```swift
// Add semantic message types (backward compatible)
extension VaporServer {
    func handleAgentMessage(_ message: AgentMessage) async throws -> AgentMessage {
        switch message {
        case .telemetry(let event):
            // Store telemetry, check for anomalies
            return .ack(event.id)

        case .remediationRequest(let action):
            // Validate, approve/reject based on policy
            let approved = try await policyEngine.evaluate(action)
            return .remediationResponse(approved: approved)

        case .escalation(let request):
            // Route to admin or AI for resolution
            let solution = try await resolutionEngine.solve(request)
            return .escalationResponse(solution: solution)

        default:
            return .error("Unknown message type")
        }
    }
}
```

**Phase 3 → Phase 4: Multi-Agent Network**
```swift
// Add peer-to-peer discovery and coordination
class AgentNetwork {
    let controlTower: ControlTowerClient
    let peerDiscovery: PeerDiscoveryService

    func joinNetwork() async throws {
        // Register with control tower
        try await controlTower.register(endpoint: self)

        // Discover peer agents
        let peers = try await peerDiscovery.findPeers()

        // Establish peer connections
        for peer in peers {
            try await establishPeerConnection(peer)
        }

        // Begin state synchronization
        try await synchronizeState()
    }

    func coordinateWithPeers(problem: Problem) async throws -> [PeerSolution] {
        // Broadcast query to peers
        let query = PeerQuery(problem: problem)
        let responses = try await broadcast(query)

        // Aggregate responses
        return responses.compactMap { $0.solution }
    }
}
```

### Proof Points: POC Validates Evolution

**1. Current REST API → WebSocket Streaming**
- ✅ POC uses Vapor framework (WS support built-in)
- ✅ JSON messaging proven in REST endpoints
- ✅ Authentication pattern extends to WS
- **Effort:** 1 sprint to add WS support

**2. WebSocket → Agent Protocol**
- ✅ Message structure already defined (ChatRequest/Response)
- ✅ Tool execution demonstrates action routing
- ✅ Error handling and validation in place
- **Effort:** 2 sprints to define semantic types

**3. Single Agent → Multi-Agent**
- ✅ Stateless API design supports clustering
- ✅ Tool registry demonstrates dynamic registration
- ✅ Async/await enables concurrent coordination
- **Effort:** 1 quarter for peer discovery + coordination

**4. Static → Federated Learning**
- ✅ Data models support metrics collection
- ✅ Privacy-first architecture (local processing)
- ✅ Secure communication foundation
- **Effort:** 2 quarters for ML pipeline

### Security Considerations for Evolution

**Phase 2: WebSocket Security**
- Mutual TLS for WS connections
- Connection rate limiting
- Message size limits
- Session timeout management

**Phase 3: Agent Protocol Security**
- Certificate-based agent identity
- Message signing and verification
- Replay attack prevention
- Audit logging of all agent actions

**Phase 4: Federated Learning Security**
- Differential privacy for model updates
- Encrypted gradient aggregation
- Model integrity verification
- Privacy budget tracking

---

This API documentation provides comprehensive information for integrating with the Breadcrumbs HTTP API. The current REST API is **production-ready for POC use** while providing a solid foundation for evolution toward a distributed agent network. Every design decision supports the vision architecture while maintaining immediate utility.

For additional help or examples, refer to the [ARCHITECTURE.md](ARCHITECTURE.md) for detailed evolution mapping or create an issue on GitHub.
