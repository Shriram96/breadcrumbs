# Security Documentation

This document outlines the security measures, known limitations, and best practices for the breadcrumbs application.

## Security Fixes Implemented

### 1. Cryptographically Secure API Key Generation ✅

**Issue**: Previously used weak random number generation for API keys.

**Fix**: 
- Now uses `SecRandomCopyBytes` for cryptographically secure random generation
- Generates 32 bytes of entropy and encodes as URL-safe base64
- Falls back to secure method only if system RNG fails

**Location**: `breadcrumbs/Services/ServiceManager.swift`

**Logging**: API key generation is logged to security category

### 2. Constant-Time API Key Comparison ✅

**Issue**: Standard string comparison is vulnerable to timing attacks.

**Fix**:
- Implemented constant-time comparison using bitwise XOR
- Prevents attackers from using response timing to guess API keys
- All comparisons take the same time regardless of where strings differ

**Location**: `breadcrumbs/Services/VaporServer.swift` - `APIKeyMiddleware`

**Logging**: Failed authentication attempts are logged with client IP

### 3. Input Validation ✅

**Issue**: No validation on chat message content or length.

**Fix**:
- Maximum message length: 100,000 characters (100KB)
- Empty message validation
- Detection of suspicious patterns (XSS, injection attempts)
- Client IP logged for all validation failures

**Location**: `breadcrumbs/Services/VaporServer.swift` - `handleChatRequest`

**Logging**: All validation failures logged to security category

### 4. Request Size Limits ✅

**Issue**: No protection against large payload DoS attacks.

**Fix**:
- Maximum request body size: 10MB
- Configured at route level
- Vapor automatically rejects oversized requests

**Location**: `breadcrumbs/Services/VaporServer.swift` - `configureRoutes`

**Logging**: Limit configuration logged on server start

### 5. Enhanced Security Logging ✅

**Issue**: Insufficient logging of security-relevant events.

**Fix**:
- New dedicated security log category (`Logger.security`)
- Authentication failures logged with client IP
- Input validation failures logged
- Server start/stop logged
- API key generation/updates logged
- Suspicious pattern detection logged

**Location**: 
- `breadcrumbs/Utilities/Logger.swift` - Security log category
- `breadcrumbs/Services/VaporServer.swift` - Security event logging
- `breadcrumbs/Services/ServiceManager.swift` - API key logging

**Viewing Logs**:
```bash
# View all security logs
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security"' --last 1h

# View in Console.app
# Open Console.app → Filter by "breadcrumbs" → Filter by "security" category
```

## Known Security Limitations

### 1. CORS Policy - Allows All Origins ⚠️

**Current State**: CORS configured with `Access-Control-Allow-Origin: *`

**Risk**: Any website can make requests to the API if they have the API key

**Mitigation**:
- Server binds to localhost only (127.0.0.1)
- Not accessible from external networks without port forwarding/tunneling
- API key authentication required

**Recommendation for Production**:
```swift
// Restrict to specific origins
response.headers.add(name: .accessControlAllowOrigin, value: "https://trusted-domain.com")
```

**Logging**: Server logs warning about CORS policy on startup

### 2. No Rate Limiting ⚠️

**Current State**: No rate limiting implemented

**Risk**: API abuse through excessive requests (DoS)

**Mitigation**:
- Localhost-only binding limits exposure
- API key authentication limits access
- Request size limits prevent payload-based DoS
- Request timeout (30 seconds) prevents long-running attacks

**Recommendation for Production**:
Implement rate limiting middleware:
```swift
struct RateLimitMiddleware: Middleware {
    let maxRequests: Int = 100
    let timeWindow: TimeInterval = 60 // 1 minute
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // Track requests per IP/API key
        // Reject if limit exceeded
    }
}
```

**Cannot Fix**: Rate limiting requires stateful tracking which is complex to implement correctly. Added comprehensive logging instead.

### 3. No HTTPS/TLS ⚠️

**Current State**: HTTP only (no TLS)

**Risk**: API keys and data transmitted in plaintext on the network

**Mitigation**:
- Server binds to localhost only
- Traffic never leaves local machine
- macOS loopback interface is isolated

**Recommendation for Production**:
- Use reverse proxy (nginx/Apache) with TLS termination
- Or implement TLS directly in Vapor
- Use Let's Encrypt for free certificates

**Cannot Fix**: TLS setup requires certificates and is beyond scope of localhost-only deployment.

### 4. Default Port May Conflict ⚠️

**Current State**: Uses port 8181 by default

**Risk**: Port may be in use or conflicting with other services

**Mitigation**:
- Port is configurable in Settings
- Error handling for port conflicts
- Clear error messages to user

**Logging**: Port conflicts logged as errors

## Security Best Practices

### For Users

1. **Protect Your API Key**
   - Treat it like a password
   - Don't share in screenshots or logs
   - Regenerate if compromised

2. **Firewall Configuration**
   - Ensure macOS firewall is enabled
   - Don't allow external connections unless needed

3. **Keep Software Updated**
   - Update macOS regularly
   - Update breadcrumbs when new versions available

4. **Monitor Logs**
   - Check security logs periodically
   - Look for failed authentication attempts
   - Report suspicious activity

### For Developers

1. **Code Review**
   - All security-related changes require review
   - Use static analysis tools
   - Test authentication and authorization

2. **Dependency Management**
   - Keep dependencies updated
   - Monitor for security advisories
   - Use `swift package audit` (when available)

3. **Testing**
   - Test authentication bypass attempts
   - Test input validation edge cases
   - Test DoS scenarios

4. **Deployment**
   - Never commit API keys to source control
   - Use environment variables for secrets
   - Enable all security logging in production

## Threat Model

### In Scope

- **Local Network Attacks**: Attacker on same machine
- **API Abuse**: Excessive requests, malformed input
- **Information Disclosure**: Logging sensitive data
- **Authentication Bypass**: Bypassing API key checks

### Out of Scope

- **Physical Access**: Attacker with physical access to machine
- **OS/Kernel Vulnerabilities**: System-level exploits
- **Social Engineering**: Tricking users into revealing API keys
- **Supply Chain**: Compromised dependencies (mitigated by code review)

## Incident Response

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email security details to repository maintainer
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Audit Trail

All security-relevant events are logged with:
- Timestamp (from OSLog)
- Event type (authentication, validation, etc.)
- Client IP address (when applicable)
- Action taken (blocked, allowed, flagged)

### Accessing Audit Logs

```bash
# View all security logs from last hour
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security"' --last 1h --style syslog

# View failed authentication attempts
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security" AND eventMessage CONTAINS "Authentication failed"' --last 24h

# View validation failures
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security" AND eventMessage CONTAINS "Validation failed"' --last 24h

# View all security events (JSON format for parsing)
log show --predicate 'subsystem == "dale.breadcrumbs" AND category == "security"' --last 7d --style json > security-audit.json
```

## Compliance Notes

### Data Privacy

- **Local Processing**: All processing occurs on user's machine
- **No External Storage**: No data sent to third parties except OpenAI
- **User Control**: Users control all data via Settings
- **Data Deletion**: Clear API key removes stored secrets

### Encryption

- **At Rest**: API keys stored in macOS Keychain (encrypted)
- **In Transit**: HTTPS used for OpenAI API (not local API)
- **In Memory**: Keys cleared on app termination

## Security Checklist for Releases

- [ ] All dependencies updated to latest versions
- [ ] No known vulnerabilities in dependencies
- [ ] Security tests passing
- [ ] Code review completed for security changes
- [ ] Security documentation updated
- [ ] Changelog includes security fixes
- [ ] Default configurations are secure

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Apple Platform Security](https://support.apple.com/guide/security/welcome/web)
- [Vapor Security Best Practices](https://docs.vapor.codes/security/overview/)
- [Swift Security Guidelines](https://swift.org/security/)

---

Last Updated: 2025-10-12
Version: 1.0.0
