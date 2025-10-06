# Breadcrumbs Remote Method Invocation (RMI)

This document describes the Remote Method Invocation architecture implemented for the breadcrumbs diagnostic app, allowing external systems to access AI diagnostic capabilities via HTTP API.

## Architecture Overview

The RMI implementation provides a **HTTP REST API** using the **Vapor framework** that exposes the breadcrumbs diagnostic capabilities to external systems. Vapor is the most popular Swift web framework with 23k+ GitHub stars, built on Apple's SwiftNIO for high-performance networking.

This allows:

- **Remote Access**: External systems can send diagnostic requests via HTTP
- **Tool Execution**: AI models can execute diagnostic tools remotely
- **Scalability**: Multiple endpoints can be managed by a central server
- **Integration**: Easy integration with existing systems and monitoring tools

## Components

### 1. Vapor HTTP Server (`VaporServer.swift`)
- **Purpose**: Core HTTP server implementation using Vapor framework
- **Features**: 
  - RESTful API endpoints
  - JSON request/response handling
  - API key authentication
  - CORS support
  - Tool execution integration
  - High-performance async/await support
  - Built-in middleware system

### 2. Service Manager (`ServiceManager.swift`)
- **Purpose**: Manages HTTP server lifecycle and configuration
- **Features**:
  - Server start/stop/restart
  - Port and API key configuration
  - Status monitoring
  - Error handling

### 3. Server Settings UI (`ServerSettingsView.swift`)
- **Purpose**: SwiftUI interface for server management
- **Features**:
  - Visual server status
  - Configuration management
  - API information display
  - Example usage

### 4. Launch Daemon Support
- **Purpose**: Run as system service
- **Files**:
  - `com.breadcrumbs.server.plist`: Launch daemon configuration
  - `ServerMode.swift`: Command-line server mode
  - `server_management.sh`: Management script

## Dependencies

The implementation uses the following Swift packages:

- **Vapor** (4.89.0+): High-performance web framework for Swift
- **SwiftNIO** (2.65.0+): Apple's event-driven network application framework
- **OpenAI** (0.4.6+): MacPaw's OpenAI Swift package for AI integration

These are added via `Package.swift` and can be managed through Xcode's Swift Package Manager integration.

## API Endpoints

### Base URL
```
http://localhost:8080/api/v1
```

### Endpoints

#### 1. Health Check
```http
GET /api/v1/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-10T10:30:00Z",
  "uptime": "5 requests processed",
  "tools_available": 1
}
```

#### 2. List Available Tools
```http
GET /api/v1/tools
```

**Response:**
```json
{
  "tools": [
    {
      "name": "vpn_detector",
      "description": "Detects if the system is currently connected to a VPN...",
      "parameters": {
        "type": "object",
        "properties": {
          "interface_name": {
            "type": "string",
            "description": "Optional: Specific network interface to check"
          }
        },
        "required": []
      }
    }
  ]
}
```

#### 3. Chat/Diagnostic Request
```http
POST /api/v1/chat
Content-Type: application/json
Authorization: Bearer <api_key>

{
  "message": "Check my VPN status",
  "conversation_id": "optional-uuid",
  "tools_enabled": true
}
```

**Response:**
```json
{
  "response": "Your VPN is currently connected via IKEv2. Here are the details:\n\nVPN Connection Status:\n- Connected: YES\n- Status: Connected\n- VPN Type: IKEv2\n- Interface: utun0\n- IP Address: 10.0.0.1\n- Connected Since: Jan 10, 2025 at 9:15 AM\n- Checked at: Jan 10, 2025 at 10:30 AM",
  "conversation_id": "uuid",
  "timestamp": "2025-01-10T10:30:00Z",
  "tools_used": ["vpn_detector"]
}
```

## Authentication

The API uses **Bearer token authentication**:

```http
Authorization: Bearer <api_key>
```

- Default API key: `demo-key-123`
- Can be configured via UI or command line
- Should be changed for production use

## Usage Examples

### 1. Using curl

```bash
# Health check
curl http://localhost:8080/api/v1/health

# List tools
curl http://localhost:8080/api/v1/tools

# Send diagnostic request
curl -X POST http://localhost:8080/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer demo-key-123" \
  -d '{
    "message": "Check my VPN status",
    "tools_enabled": true
  }'
```

### 2. Using Python Client

```python
import requests

client = requests.Session()
client.headers.update({
    'Content-Type': 'application/json',
    'Authorization': 'Bearer demo-key-123'
})

# Send diagnostic request
response = client.post('http://localhost:8080/api/v1/chat', json={
    'message': 'Check my VPN status',
    'tools_enabled': True
})

result = response.json()
print(result['response'])
```

### 3. Using the Test Client

```bash
# Run the included Python test client
python3 test_client.py
```

## Deployment Options

### 1. Manual Start (Development/Testing)

```bash
# Start server manually
./scripts/server_management.sh start

# Check status
./scripts/server_management.sh status

# Test API
./scripts/server_management.sh test

# Stop server
./scripts/server_management.sh stop
```

### 2. Launch Daemon (Production)

```bash
# Install as system service (requires sudo)
sudo ./scripts/server_management.sh install

# Check status
./scripts/server_management.sh status

# Uninstall
sudo ./scripts/server_management.sh uninstall
```

### 3. Command Line Server Mode

```bash
# Run in server mode with custom options
./breadcrumbs --server-mode --port 8080 --api-key my-secret-key

# Run as daemon
./breadcrumbs --server-mode --daemon --port 8080
```

## Configuration

### Environment Variables

- `BREADCRUMBS_SERVER_MODE`: Set to "1" to enable server mode
- `BREADCRUMBS_PORT`: Server port (default: 8080)
- `BREADCRUMBS_API_KEY`: API key for authentication
- `OPENAI_API_KEY`: OpenAI API key for AI model

### Launch Daemon Configuration

The launch daemon configuration (`com.breadcrumbs.server.plist`) includes:

- Automatic startup on system boot
- Process monitoring and restart
- Resource limits
- Log file locations
- Environment variables

## Security Considerations

### Current Implementation
- **API Key Authentication**: Basic bearer token authentication
- **Localhost Only**: Server binds to localhost by default
- **CORS Support**: Configured for cross-origin requests

### Production Recommendations
1. **Change Default API Key**: Use a strong, unique API key
2. **HTTPS**: Implement TLS/SSL for encrypted communication
3. **Network Security**: Configure firewall rules appropriately
4. **Rate Limiting**: Implement request rate limiting
5. **Input Validation**: Enhanced input validation and sanitization
6. **Audit Logging**: Comprehensive request/response logging

## Monitoring and Logging

### Log Files
- **Application Logs**: `/tmp/breadcrumbs-server.log`
- **Error Logs**: `/tmp/breadcrumbs-server-error.log`
- **System Logs**: `log show --predicate 'process == "breadcrumbs"'`

### Health Monitoring
- **Health Endpoint**: `/api/v1/health` for basic health checks
- **Process Monitoring**: Launch daemon automatically restarts on failure
- **Resource Monitoring**: Built-in resource limits

## Integration Examples

### 1. Central Management Server

A central server can manage multiple breadcrumbs endpoints:

```python
endpoints = [
    "http://machine1.local:8080",
    "http://machine2.local:8080",
    "http://machine3.local:8080"
]

for endpoint in endpoints:
    client = BreadcrumbsClient(base_url=endpoint)
    result = client.test_vpn_detection()
    print(f"{endpoint}: {result['response']}")
```

### 2. Monitoring Integration

```bash
# Nagios/Icinga check
curl -f http://localhost:8080/api/v1/health || exit 2

# Prometheus metrics (custom endpoint needed)
curl http://localhost:8080/api/v1/metrics
```

### 3. CI/CD Integration

```yaml
# GitHub Actions example
- name: Test VPN Detection
  run: |
    curl -X POST http://localhost:8080/api/v1/chat \
      -H "Authorization: Bearer ${{ secrets.API_KEY }}" \
      -d '{"message": "Check VPN status", "tools_enabled": true}'
```

## Troubleshooting

### Common Issues

1. **Server Won't Start**
   - Check if port 8080 is available: `lsof -i :8080`
   - Verify OpenAI API key is configured
   - Check logs: `./scripts/server_management.sh logs`

2. **API Requests Failing**
   - Verify server is running: `./scripts/server_management.sh status`
   - Check API key: Must match server configuration
   - Test with curl first before using custom clients

3. **Launch Daemon Issues**
   - Check daemon status: `launchctl list | grep breadcrumbs`
   - View system logs: `log show --predicate 'process == "breadcrumbs"'`
   - Reload daemon: `sudo launchctl unload/load /Library/LaunchDaemons/com.breadcrumbs.server.plist`

### Debug Mode

```bash
# Run with verbose logging
./breadcrumbs --server-mode --verbose --port 8080
```

## Future Enhancements

### Planned Features
1. **WebSocket Support**: Real-time bidirectional communication
2. **gRPC Interface**: High-performance RPC protocol
3. **Authentication**: OAuth2/JWT token support
4. **Rate Limiting**: Request throttling and quotas
5. **Metrics**: Prometheus-compatible metrics endpoint
6. **Load Balancing**: Multiple server instances
7. **TLS/SSL**: Encrypted communication
8. **API Versioning**: Multiple API versions support

### Advanced RMI Options

1. **Distributed Actor Model**: Using Swift's Actor system
2. **Message Queue Integration**: Redis/RabbitMQ for async processing
3. **Service Discovery**: Automatic endpoint discovery
4. **Circuit Breaker**: Fault tolerance patterns
5. **Distributed Tracing**: Request tracing across services

## Conclusion

The HTTP REST API approach provides a solid foundation for remote access to breadcrumbs diagnostic capabilities. It's simple to implement, easy to test, and provides good integration options for external systems.

For your demo requirements, this implementation allows you to:
- Start a server on localhost:8080
- Send GET requests for health checks
- Send POST requests with prompts
- Receive diagnostic results from AI + tools

The architecture is extensible and can be enhanced with additional features as needed for production use.
